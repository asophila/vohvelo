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
NC='\033[0m' # No Color

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
Usage: $SCRIPT_NAME [options] <remote_user> <remote_host> <command> [args...]

Executes a command on a remote machine and retrieves the results.

Arguments:
  remote_user   Username for SSH connection
  remote_host   Remote hostname or IP address
  command       Command to execute on the remote machine
  args          Arguments for the command (including input/output files)

Options:
  -h, --help    Show this help message and exit
  -v, --version Show version information and exit
  -i FILE       Input file to copy to remote machine
  -o FILE       Output file to copy back from remote machine
  -d            Debug mode (show detailed progress)

Examples:
  # Transcode a video file
  $SCRIPT_NAME -i video.mkv -o output.mp4 user host ffmpeg -i video.mkv -vcodec libx264 output.mp4

  # Process multiple input files
  $SCRIPT_NAME -i file1.txt -i file2.txt -o result.txt user host "cat file1.txt file2.txt > result.txt"

  # Run any command
  $SCRIPT_NAME user host "ls -la"

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
    local user="$1"
    local host="$2"
    
    # Setup SSH control socket directory
    sshfifos=~/.ssh/controlmasters
    [[ -d $sshfifos ]] || mkdir -p "$sshfifos"
    chmod 755 "$sshfifos"
    
    # Create control socket path
    ctl="$sshfifos/$user@$host:22"
    
    # Setup trap to close SSH connection on exit
    trap 'cleanup_ssh_connection' EXIT
    
    # Start SSH control connection
    if ! ssh -fNMS "$ctl" "$user@$host"; then
        error "Failed to establish SSH connection to $user@$host"
    fi
    
    success "SSH connection established"
}

# Function to cleanup SSH connection
cleanup_ssh_connection() {
    if [[ -n "${ctl:-}" ]]; then
        ssh -S "$ctl" -O exit "$user@$host" 2>/dev/null || true
        success "SSH connection closed"
    fi
}

# Function to create remote temporary directory
create_remote_temp_dir() {
    local user="$1"
    local host="$2"
    
    local remote_dir
    remote_dir=$(ssh -S "$ctl" "$user@$host" "mktemp -d /tmp/vohvelo.XXXXXX") || error "Failed to create remote temporary directory"
    echo "$remote_dir"
}

# Function to copy file to remote host
copy_to_remote() {
    local file="$1"
    local user="$2"
    local host="$3"
    local remote_dir="$4"
    
    echo "Copying $(basename "$file") to remote host..."
    if ! scp -o ControlPath="$ctl" "$file" "$user@$host:$remote_dir/"; then
        error "Failed to copy file to remote host"
    fi
    success "File copied successfully"
}

# Function to copy file from remote host
copy_from_remote() {
    local remote_file="$1"
    local local_file="$2"
    local user="$3"
    local host="$4"
    
    echo "Copying result from remote host..."
    if ! scp -o ControlPath="$ctl" "$user@$host:$remote_file" "$local_file"; then
        error "Failed to copy file from remote host"
    fi
    success "File retrieved successfully"
}

# Function to cleanup remote directory
cleanup_remote_dir() {
    local user="$1"
    local host="$2"
    local remote_dir="$3"
    
    echo "Cleaning up remote directory..."
    if ! ssh -S "$ctl" "$user@$host" "rm -rf '$remote_dir'"; then
        warn "Failed to cleanup remote directory: $remote_dir"
    fi
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            ;;
        -v|--version)
            show_version
            ;;
        *)
            break
            ;;
    esac
    shift
done

# Initialize arrays for input and output files
declare -a input_files=()
declare -a output_files=()
debug_mode=false

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            ;;
        -v|--version)
            show_version
            ;;
        -i)
            shift
            [[ $# -eq 0 ]] && error "Missing argument for -i"
            input_files+=("$1")
            shift
            ;;
        -o)
            shift
            [[ $# -eq 0 ]] && error "Missing argument for -o"
            output_files+=("$1")
            shift
            ;;
        -d)
            debug_mode=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Check required arguments
if [[ $# -lt 3 ]]; then
    error "Missing required arguments\nUse '$SCRIPT_NAME --help' for usage information"
fi

# Get arguments
user="$1"
host="$2"
shift 2
remote_command="$*"

# Debug output
if [[ "$debug_mode" == true ]]; then
    echo "Input files: ${input_files[*]}"
    echo "Output files: ${output_files[*]}"
    echo "Remote command: $remote_command"
fi

# Validate input files
for file in "${input_files[@]}"; do
    validate_input_file "$file"
done

# Validate output paths
for file in "${output_files[@]}"; do
    validate_output_path "$file"
done

# Generate random directory name for remote files
remote_dir_name="vohvelo_$(head -c 8 /dev/urandom | xxd -p)"

# Setup SSH connection
setup_ssh_connection "$user" "$host"

# Create remote temporary directory
remote_dir=$(create_remote_temp_dir "$user" "$host")
echo "Remote directory: $remote_dir"

# Copy input files to remote host
for file in "${input_files[@]}"; do
    copy_to_remote "$file" "$user" "$host" "$remote_dir"
done

# Prepare command with correct paths
modified_command="$remote_command"
for file in "${input_files[@]}"; do
    filename=$(basename "$file")
    modified_command=${modified_command//"$filename"/"$remote_dir/$filename"}
done
for file in "${output_files[@]}"; do
    filename=$(basename "$file")
    modified_command=${modified_command//"$filename"/"$remote_dir/$filename"}
done

# Execute remote process
echo "Starting remote process..."
if ! ssh -S "$ctl" "$user@$host" "$modified_command"; then
    error "Remote process failed"
fi
success "Remote process completed"

# Copy output files back
for file in "${output_files[@]}"; do
    filename=$(basename "$file")
    copy_from_remote "$remote_dir/$filename" "$file" "$user" "$host"
done

# Cleanup remote directory
cleanup_remote_dir "$user" "$host" "$remote_dir"

success "Process completed successfully"
if [[ ${#output_files[@]} -gt 0 ]]; then
    echo "Output files:"
    printf '%s\n' "${output_files[@]}"
fi
