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
Usage: $SCRIPT_NAME [options] <input_file> <remote_user> <remote_host> <output_file>

Executes processes on a remote machine and retrieves the results.

Arguments:
  input_file    Path to the input file to process
  remote_user   Username for SSH connection
  remote_host   Remote hostname or IP address
  output_file   Path for the output file

Options:
  -h, --help    Show this help message and exit
  -v, --version Show version information and exit

Example:
  $SCRIPT_NAME video.mkv user 192.168.1.100 output.mp4

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

# Check required arguments
if [[ $# -ne 4 ]]; then
    error "Missing required arguments\nUse '$SCRIPT_NAME --help' for usage information"
fi

# Get arguments
input_file="$1"
user="$2"
host="$3"
output_file="$4"

# Convert paths to absolute paths
input_file=$(readlink -f "$input_file" 2>/dev/null || echo "$input_file")
output_file=$(readlink -f "$output_file" 2>/dev/null || echo "$output_file")

# Validate input and output
validate_input_file "$input_file"
validate_output_path "$output_file"

# Get file extension for temporary filename
extension="${output_file##*.}"
rnd_filename="vohvelo_$(head -c 8 /dev/urandom | xxd -p).$extension"
echo "Using temporary filename: $rnd_filename"

# Setup SSH connection
setup_ssh_connection "$user" "$host"

# Create remote temporary directory
remote_dir=$(create_remote_temp_dir "$user" "$host")
echo "Remote directory: $remote_dir"

# Copy input file to remote host
copy_to_remote "$input_file" "$user" "$host" "$remote_dir"

# Execute remote process
echo "Starting remote process..."
if ! ssh -S "$ctl" "$user@$host" "ffmpeg -hwaccel auto -i '$remote_dir/$(basename "$input_file")' -bsf:v h264_mp4toannexb -sn -map 0:0 -map 0:1 -vcodec libx264 '$remote_dir/$rnd_filename'"; then
    error "Remote process failed"
fi
success "Remote process completed"

# Copy result back
copy_from_remote "$remote_dir/$rnd_filename" "$output_file" "$user" "$host"

# Cleanup remote directory
cleanup_remote_dir "$user" "$host" "$remote_dir"

success "Process completed successfully"
echo "Output file: $output_file"
