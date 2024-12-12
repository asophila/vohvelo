#!/bin/bash

# Vohvelo: Advanced Remote Process Execution Script
# Usage: ./vohvelo.sh [options] <remote user> <remote host> <remote command> <input file(s)> <output file>

set -e

# Default values
CONFIG_FILE="$HOME/.vohvelo.conf"
LOG_FILE="vohvelo.log"
BANDWIDTH_LIMIT=""
COMPRESSION=false
RETRIES=3
PARALLEL=1

# Configuration file format:
# The configuration file should be in bash syntax and can set the following variables:
# LOG_FILE="path/to/logfile"
# BANDWIDTH_LIMIT="1m"  # Example: 1m for 1MB/s
# COMPRESSION=true      # or false
# RETRIES=5
# PARALLEL=4
# 
# Example configuration file content:
# LOG_FILE="/var/log/vohvelo.log"
# BANDWIDTH_LIMIT="2m"
# COMPRESSION=true
# RETRIES=5
# PARALLEL=2

# Function to display usage information
usage() {
    echo "Usage: $0 [options] <remote user> <remote host> <remote command> <input file(s)> <output file>"
    echo "Options:"
    echo "  -c, --config <file>     Specify a configuration file (default: $CONFIG_FILE)"
    echo "  -l, --log <file>        Specify a log file (default: $LOG_FILE)"
    echo "  -b, --bandwidth <limit> Set bandwidth limit for file transfers (e.g., 1m for 1MB/s)"
    echo "  -z, --compress          Enable compression for file transfers"
    echo "  -r, --retries <num>     Set number of retries for network operations (default: $RETRIES)"
    echo "  -p, --parallel <num>    Set number of parallel executions (default: $PARALLEL)"
    echo "  -h, --help              Display this help message"
    exit 1
}

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to execute remote command with progress
execute_remote() {
    local input=$1
    local output=$2
    local remote_input="$rmtdir/$(basename "$input")"
    local remote_output="$rmtdir/$(basename "$output")"

    log "Copying input file to remote host..."
    scp $COMPRESSION_FLAG $BANDWIDTH_FLAG -o ControlPath=$ctl "$input" $user@$host:$remote_input

    log "Executing remote command..."
    ssh -S $ctl $user@$host "$remote_cmd '$remote_input' '$remote_output'" &
    pid=$!

    while kill -0 $pid 2>/dev/null; do
        echo -n "."
        sleep 1
    done
    wait $pid
    echo

    log "Copying output file from remote host..."
    scp $COMPRESSION_FLAG $BANDWIDTH_FLAG -o ControlPath=$ctl $user@$host:$remote_output "$output"

    log "Cleaning up remote files..."
    ssh -S $ctl $user@$host "rm '$remote_input' '$remote_output'"
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config) CONFIG_FILE="$2"; shift 2 ;;
        -l|--log) LOG_FILE="$2"; shift 2 ;;
        -b|--bandwidth) BANDWIDTH_LIMIT="$2"; shift 2 ;;
        -z|--compress) COMPRESSION=true; shift ;;
        -r|--retries) RETRIES="$2"; shift 2 ;;
        -p|--parallel) PARALLEL="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) break ;;
    esac
done

# Check for correct number of arguments
if [ $# -lt 5 ]; then
    usage
fi

# Load configuration file if it exists
if [ -f "$CONFIG_FILE" ]; then
    log "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
else
    log "No configuration file found at $CONFIG_FILE, using default values"
fi

# Assign arguments to variables
user=$1
host=$2
remote_cmd=$3
input_files=("${@:4:${#@}-4}")
output_file="${!#}"

# Set flags based on options
COMPRESSION_FLAG=$([[ "$COMPRESSION" == true ]] && echo "-C" || echo "")
BANDWIDTH_FLAG=$([[ -n "$BANDWIDTH_LIMIT" ]] && echo "-l $BANDWIDTH_LIMIT" || echo "")

# Initialize log file
> "$LOG_FILE"

log "Starting Vohvelo execution"

# Set up SSH control connection
trap 'log "Closing SSH connection"; ssh -S $ctl -O exit $user@$host' EXIT
sshfifos=~/.ssh/controlmasters
[ -d $sshfifos ] || mkdir -p $sshfifos
ctl=$sshfifos/$user@$host:22

# Establish SSH control connection with retries
for i in $(seq 1 $RETRIES); do
    if ssh -fNMS $ctl $user@$host; then
        log "SSH connection established"
        break
    elif [ $i -eq $RETRIES ]; then
        log "Error: Failed to establish SSH connection after $RETRIES attempts"
        exit 1
    else
        log "SSH connection attempt $i failed, retrying..."
        sleep 5
    fi
done

# Extract the command name
cmd_name=$(echo "$remote_cmd" | awk '{print $1}')

# Check if the command exists on the remote machine
if ! ssh -S $ctl $user@$host "command -v $cmd_name > /dev/null 2>&1"; then
    log "Error: Command '$cmd_name' not found on the remote machine"
    exit 1
fi

# Create remote temp folder
rmtdir=$(ssh -S $ctl $user@$host "mktemp -d /tmp/XXXX")
log "Created remote temporary directory: $rmtdir"

# Process files in parallel
for input in "${input_files[@]}"; do
    output="${input%.*}_processed.${output_file##*.}"
    execute_remote "$input" "$output" &
    if [[ $(jobs -r -p | wc -l) -ge $PARALLEL ]]; then
        wait -n
    fi
done

# Wait for all background jobs to finish
wait

log "Cleaning up remote temporary directory"
ssh -S $ctl $user@$host "rm -rf '$rmtdir'"

log "Vohvelo execution completed successfully"
