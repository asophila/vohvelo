#!/bin/bash

# Vohvelo - Remote Process Execution Tool
# Executes processes on a remote machine and retrieves the results

set -e  # Exit on error
set -u  # Exit on undefined variable

# Constants
VERSION="1.0.0"
SCRIPT_NAME=$(basename "$0")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
declare -g sshfifos  # SSH control socket directory
declare -g ctl       # Current SSH control socket path

# Job queue
declare -a job_queue=()
declare -A job_status=()

# Function to display error messages
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to display warning messages
warn() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

# Function to display success messages
success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [options]

Options:
  -i, --input FILE      Input file to copy to remote machine (can be used multiple times)
  -o, --output FILE     Output file to copy back (can be used multiple times)
  -h, --host HOST       Remote host in user@hostname format
  -c, --command CMD     Command to execute on the remote machine
  -I, --interactive     Enter interactive job creation mode
  -d, --debug          Enable debug mode
  -q, --quiet          Suppress progress output
  -j, --job-file FILE  Load job definition from file
  -s, --save-job FILE  Save job definition to file for later use
  -p, --parallel N     Run up to N jobs in parallel (default: 1)
  -w, --wait           Wait for all jobs to complete before exiting
      --help           Show this help message and exit
  -v, --version        Show version information and exit

Examples:
  # Basic command execution
  $SCRIPT_NAME -h user@host -c "ls -la"

  # Process a file
  $SCRIPT_NAME -i input.txt -o output.txt -h user@host -c "sort input.txt > output.txt"

  # Video transcoding
  $SCRIPT_NAME -i video.mkv -o video.mp4 -h user@host \\
    -c "ffmpeg -i video.mkv -c:v libx264 video.mp4"

  # Multiple input files
  $SCRIPT_NAME -i file1.txt -i file2.txt -o result.txt -h user@host \\
    -c "cat file1.txt file2.txt > result.txt"

  # Interactive job creation
  $SCRIPT_NAME --interactive

Note: Both relative and absolute paths are supported for input and output files.
EOF
    exit 0
}

# Function to show version information
show_version() {
    echo "Vohvelo v$VERSION"
    exit 0
}

# Function to validate input file
validate_input_file() {
    local input_file="$1"
    
    # Check if input file exists
    if [[ ! -f "$input_file" ]]; then
        error "Input file does not exist: $input_file"
    fi
    
    # Check if input file is readable
    if [[ ! -r "$input_file" ]]; then
        error "Input file is not readable: $input_file"
    fi
}

# Function to validate output path
validate_output_path() {
    local output_file="$1"
    local output_dir
    
    # Get directory path from output file
    output_dir=$(dirname "$output_file")
    
    # If output directory doesn't exist, try to create it
    if [[ ! -d "$output_dir" ]]; then
        mkdir -p "$output_dir" || error "Cannot create output directory: $output_dir"
    fi
    
    # Check if output directory is writable
    if [[ ! -w "$output_dir" ]]; then
        error "Output directory is not writable: $output_dir"
    fi
}

# Function to setup SSH control connection
setup_ssh_connection() {
    local connection_user="$1"
    local connection_host="$2"
    
    # Setup SSH control socket directory
    sshfifos=~/.ssh/controlmasters
    [[ -d $sshfifos ]] || mkdir -p "$sshfifos"
    chmod 755 "$sshfifos"
    
    # Create control socket path
    ctl="$sshfifos/$connection_user@$connection_host:22"
    
    # Setup trap to close SSH connection on exit
    trap 'cleanup_ssh_connection' EXIT INT TERM
    
    # Start SSH control connection
    if ! ssh -fNMS "$ctl" "$connection_user@$connection_host"; then
        error "Failed to establish SSH connection to $connection_user@$connection_host"
    fi
    
    success "SSH connection established"
}

# Function to cleanup SSH connection
cleanup_ssh_connection() {
    if [[ -n "${ctl:-}" ]]; then
        # Extract connection info from ctl path
        local connection_info
        connection_info=$(basename "$ctl" | sed 's/:22$//')
        
        if [[ -e "$ctl" ]]; then
            # Close the connection
            ssh -S "$ctl" -O exit "$connection_info" 2>/dev/null || true
            rm -f "$ctl" 2>/dev/null
            [[ "$quiet_mode" != true ]] && success "SSH connection closed"
        fi
        
        # Clear the global ctl variable
        ctl=""
    fi
}

# Function to create remote temporary directory
create_remote_temp_dir() {
    local connection_user="$1"
    local connection_host="$2"
    
    local remote_dir
    remote_dir=$(ssh -S "$ctl" "$connection_user@$connection_host" "mktemp -d /tmp/vohvelo.XXXXXX") || error "Failed to create remote temporary directory"
    echo "$remote_dir"
}

# Function to copy file to remote host
copy_to_remote() {
    local file="$1"
    local connection_user="$2"
    local connection_host="$3"
    local remote_dir="$4"
    
    echo "Copying $(basename "$file") to remote host..."
    if ! scp -o ControlPath="$ctl" "$file" "$connection_user@$connection_host:$remote_dir/"; then
        error "Failed to copy file to remote host"
    fi
    success "File copied successfully"
}

# Function to copy file from remote host
copy_from_remote() {
    local remote_file="$1"
    local local_file="$2"
    local connection_user="$3"
    local connection_host="$4"
    
    echo "Copying result from remote host..."
    if ! scp -o ControlPath="$ctl" "$connection_user@$connection_host:$remote_file" "$local_file"; then
        error "Failed to copy file from remote host"
    fi
    success "File retrieved successfully"
}

# Function to cleanup remote directory
cleanup_remote_dir() {
    local connection_user="$1"
    local connection_host="$2"
    local remote_dir="$3"
    
    echo "Cleaning up remote directory..."
    if ! ssh -S "$ctl" "$connection_user@$connection_host" "rm -rf '$remote_dir'"; then
        warn "Failed to cleanup remote directory: $remote_dir"
    fi
}

# Function to create a new job
create_job() {
    local -a job_inputs=()
    local -a job_outputs=()
    local job_host
    local job_command
    
    # Parse input arrays
    if [[ -n "${1:-}" ]]; then
        read -r -a job_inputs <<< "$1"
    fi
    
    if [[ -n "${2:-}" ]]; then
        read -r -a job_outputs <<< "$2"
    fi
    
    job_host="${3:-}"
    job_command="${4:-}"
    
    # Create job definition
    local job="job_inputs=(${job_inputs[*]:-}); job_outputs=(${job_outputs[*]:-}); job_host=$job_host; job_command=$job_command"
    job_queue+=("$job")
    job_status["${#job_queue[@]}-1"]="pending"
}

# Function to run interactive mode
run_interactive_mode() {
    echo -e "\n${BLUE}Vohvelo Interactive Job Creator v$VERSION${NC}"
    echo -e "${BLUE}-----------------------------------${NC}\n"
    
    local job_count=0
    local last_host=""
    
    while true; do
        job_count=$((job_count + 1))
        echo "Job #$job_count:"
        
        # Get host
        local default_host="${last_host:-}"
        local host
        if [[ -n "$default_host" ]]; then
            read -p "Remote host [$default_host] (e.g., user@hostname): " host
            host="${host:-$default_host}"
        else
            read -p "Remote host (e.g., user@hostname): " host
        fi
        last_host="$host"
        
        # Get input files
        echo -e "\nInput files (press enter without typing anything to finish):"
        echo "Examples: data.csv, script.py, config.json"
        local -a inputs=()
        local file_num=1
        while true; do
            read -p "Input file #$file_num: " input
            [[ -z "$input" ]] && break
            if [[ -f "$input" ]]; then
                inputs+=("$input")
                ((file_num++))
            else
                echo -e "${YELLOW}Warning: File '$input' not found${NC}"
                read -p "Use anyway? [y/N] " yn
                if [[ "${yn,,}" == "y" ]]; then
                    inputs+=("$input")
                    ((file_num++))
                fi
            fi
        done
        
        # Get output files
        echo -e "\nOutput files (press enter without typing anything to finish):"
        echo "Examples: results.txt, output.pdf, processed.mp4"
        local -a outputs=()
        local seen_outputs=()
        local file_num=1
        while true; do
            read -p "Output file #$file_num: " output
            [[ -z "$output" ]] && break
            
            # Check for duplicates
            if [[ " ${seen_outputs[*]} " =~ " ${output} " ]]; then
                echo -e "${YELLOW}Warning: Output file '$output' already added${NC}"
                continue
            fi
            
            outputs+=("$output")
            seen_outputs+=("$output")
            ((file_num++))
        done
        
        # Get command
        echo -e "\nCommand to run on remote host:"
        echo "Examples: ls -la, python3 script.py, ffmpeg -i input.mp4 output.mp4"
        read -p "Command: " command
        
        # Show command preview
        echo -e "\nJob created:"
        echo "$SCRIPT_NAME \\"
        for input in "${inputs[@]}"; do
            echo "  -i \"$input\" \\"
        done
        for output in "${outputs[@]}"; do
            echo "  -o \"$output\" \\"
        done
        echo "  -h \"$host\" \\"
        echo "  -c \"$command\""
        
        # Create job
        create_job "${inputs[*]:-}" "${outputs[*]:-}" "$host" "$command"
        
        # Ask to add another job
        read -p $'\nAdd another job? [y/N]: ' add_another
        [[ "${add_another,,}" != "y" ]] && break
        echo
    done
    
    # Initialize job status array
    for i in "${!job_queue[@]}"; do
        job_status[$i]="pending"
    done
    
    # Show job summary
    echo -e "\n${BLUE}Job Queue Summary${NC}"
    echo -e "${BLUE}----------------${NC}"
    for i in "${!job_queue[@]}"; do
        echo "Job #$((i+1)): ${job_status[$i]}"
    done
    
    # Ask to run jobs
    read -p $'\nRun jobs now? [Y/n]: ' run_now
    [[ "${run_now,,}" != "n" ]] && run_job_queue
}

# Function to process a single job
process_job() {
    local -a job_inputs=()
    local -a job_outputs=()
    local job_host
    local job_command
    
    # Parse input arrays
    if [[ -n "${1:-}" ]]; then
        read -r -a job_inputs <<< "$1"
    fi
    
    if [[ -n "${2:-}" ]]; then
        read -r -a job_outputs <<< "$2"
    fi
    
    job_host="${3:-}"
    job_command="${4:-}"
    
    [[ "$debug_mode" == true ]] && {
        echo "Input files: ${job_inputs[*]:-}"
        echo "Output files: ${job_outputs[*]:-}"
        echo "Host: $job_host"
        echo "Command: $job_command"
    }
    
    # Split host into user and hostname
    local job_user job_hostname
    IFS='@' read -r job_user job_hostname <<< "$job_host"
    if [[ -z "$job_user" || -z "$job_hostname" ]]; then
        error "Invalid host format. Use 'user@hostname'"
        return 1
    fi
    
    # Setup SSH connection
    setup_ssh_connection "$job_user" "$job_hostname"
    
    # Create remote temporary directory
    local job_remote_dir
    job_remote_dir=$(create_remote_temp_dir "$job_user" "$job_hostname")
    [[ "$debug_mode" == true ]] && echo "Remote directory: $job_remote_dir"
    
    # Copy input files to remote host
    for file in "${job_inputs[@]}"; do
        copy_to_remote "$file" "$job_user" "$job_hostname" "$job_remote_dir"
    done
    
    # Prepare command with correct paths
    local modified_job_command="$job_command"
    for file in "${job_inputs[@]}"; do
        filename=$(basename "$file")
        modified_job_command=${modified_job_command//"$filename"/"$job_remote_dir/$filename"}
    done
    for file in "${job_outputs[@]}"; do
        filename=$(basename "$file")
        modified_job_command=${modified_job_command//"$filename"/"$job_remote_dir/$filename"}
    done
    
    # Execute remote process
    [[ "$quiet_mode" != true ]] && echo "Starting remote process..."
    if ! ssh -S "$ctl" "$job_user@$job_hostname" "$modified_job_command"; then
        error "Remote process failed"
        return 1
    fi
    [[ "$quiet_mode" != true ]] && success "Remote process completed"
    
    # Copy output files back
    for file in "${job_outputs[@]}"; do
        filename=$(basename "$file")
        copy_from_remote "$job_remote_dir/$filename" "$file" "$job_user" "$job_hostname"
    done
    
    # Cleanup remote directory
    cleanup_remote_dir "$job_user" "$job_hostname" "$job_remote_dir"
    
    return 0
}

# Function to run the job queue
run_job_queue() {
    local total_jobs=${#job_queue[@]}
    echo -e "\nRunning $total_jobs jobs..."
    
    for i in "${!job_queue[@]}"; do
        echo -e "\n${BLUE}Running Job #$((i+1))${NC}"
        job_status[$i]="running"
        
        # Create local variables for job
        local -a job_inputs=()
        local -a job_outputs=()
        local job_host=""
        local job_command=""
        
        # Evaluate job definition to set local variables
        eval "${job_queue[$i]}"
        
        # Run the job
        if process_job "${job_inputs[*]:-}" "${job_outputs[*]:-}" "$job_host" "$job_command"; then
            job_status[$i]="completed"
            echo -e "${GREEN}Job #$((i+1)) completed successfully${NC}"
        else
            job_status[$i]="failed"
            echo -e "${RED}Job #$((i+1)) failed${NC}"
            [[ "$wait_mode" != true ]] && error "Job failed and --wait not specified"
        fi
    done
    
    # Show final summary
    echo -e "\n${BLUE}Final Job Status${NC}"
    echo -e "${BLUE}---------------${NC}"
    for i in "${!job_queue[@]}"; do
        echo "Job #$((i+1)): ${job_status[$i]}"
    done
}

# Initialize variables
declare -a input_files=()
declare -a output_files=()
host=""
command=""
debug_mode=false
quiet_mode=false
interactive_mode=false
parallel_jobs=1
wait_mode=false
job_file=""
save_job=""

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_usage
            ;;
        -v|--version)
            show_version
            ;;
        -i|--input)
            shift
            [[ $# -eq 0 ]] && error "Missing argument for -i/--input"
            input_files+=("$1")
            shift
            ;;
        -o|--output)
            shift
            [[ $# -eq 0 ]] && error "Missing argument for -o/--output"
            output_files+=("$1")
            shift
            ;;
        -h|--host)
            shift
            [[ $# -eq 0 ]] && error "Missing argument for -h/--host"
            host="$1"
            shift
            ;;
        -c|--command)
            shift
            [[ $# -eq 0 ]] && error "Missing argument for -c/--command"
            command="$1"
            shift
            ;;
        -I|--interactive)
            interactive_mode=true
            shift
            ;;
        -d|--debug)
            debug_mode=true
            shift
            ;;
        -q|--quiet)
            quiet_mode=true
            shift
            ;;
        -j|--job-file)
            shift
            [[ $# -eq 0 ]] && error "Missing argument for -j/--job-file"
            job_file="$1"
            shift
            ;;
        -s|--save-job)
            shift
            [[ $# -eq 0 ]] && error "Missing argument for -s/--save-job"
            save_job="$1"
            shift
            ;;
        -p|--parallel)
            shift
            [[ $# -eq 0 ]] && error "Missing argument for -p/--parallel"
            parallel_jobs="$1"
            shift
            ;;
        -w|--wait)
            wait_mode=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Check if interactive mode is requested
if [[ "$interactive_mode" == true ]]; then
    run_interactive_mode
    exit 0
fi

# Check required arguments in non-interactive mode
if [[ -z "$host" ]]; then
    error "Missing required argument: -h/--host\nUse '$SCRIPT_NAME --help' for usage information"
fi

if [[ -z "$command" ]]; then
    error "Missing required argument: -c/--command\nUse '$SCRIPT_NAME --help' for usage information"
fi

# Validate input files
for file in "${input_files[@]}"; do
    validate_input_file "$file"
done

# Validate output paths
for file in "${output_files[@]}"; do
    validate_output_path "$file"
done

# Process the job
if process_job "${input_files[*]:-}" "${output_files[*]:-}" "$host" "$command"; then
    success "Process completed successfully"
    if [[ ${#output_files[@]} -gt 0 ]]; then
        echo "Output files:"
        printf '%s\n' "${output_files[@]}"
    fi
    exit 0
else
    error "Process failed"
fi
