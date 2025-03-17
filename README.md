# 🚀 Vohvelo

![Vohvelo Logo](images/vohvelo-logo.png)

> Vohvelo [βo̞ʰ ve̞lo̞ʰ] is a powerful tool for executing processes on remote machines. It automates the entire workflow of file transfers, remote execution, and result retrieval, making distributed processing seamless and efficient.

## 📖 Table of Contents
- [Features](#-features)
- [Installation](#-installation)
- [Basic Usage](#-basic-usage)
- [Advanced Usage](#-advanced-usage)
  - [Interactive Mode](#interactive-mode)
  - [Job Queue](#job-queue)
  - [Video Processing](#video-processing)
  - [Data Processing](#data-processing)
  - [Multiple Files](#multiple-files)
  - [Debug Mode](#debug-mode)
- [Command Reference](#-command-reference)
- [Use Cases](#-use-cases)
- [Future Improvements](#-future-improvements)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **Universal Command Execution**: Run any command on remote machines
- **Interactive Job Creation**: Create and manage multiple jobs interactively
- **Job Queue Management**: Queue multiple jobs and execute them sequentially
- **Multiple File Support**: Handle multiple input and output files
- **Robust Error Handling**: Comprehensive validation and error messages
- **Path Flexibility**: Support for both relative and absolute paths
- **Space-Safe**: Properly handle filenames containing spaces
- **Secure**: Use SSH for secure file transfers and execution
- **Clean**: Automatic temporary file management
- **User-Friendly**: Colored output and progress indicators
- **Efficient**: SSH control connections for faster operations
- **Debug Mode**: Detailed progress information for troubleshooting
- **Parallel Processing**: Infrastructure for running multiple jobs in parallel
- **Wait Mode**: Option to continue on job failure
- **Job Files**: Save and load job definitions

## 📥 Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/bicubico/vohvelo.git
   cd vohvelo
   ```

2. Make the script executable:
   ```bash
   chmod +x vohvelo.sh
   ```

3. (Optional) Add to your PATH:
   ```bash
   sudo cp vohvelo.sh /usr/local/bin/vohvelo
   ```

### Prerequisites

- bash
- ssh
- scp

## 🚀 Basic Usage

The basic syntax is:
```bash
vohvelo.sh [options]
```

### Options
- `-i, --input FILE`: Input file to copy to remote machine (can be used multiple times)
- `-o, --output FILE`: Output file to copy back (can be used multiple times)
- `-h, --host HOST`: Remote host in user@hostname format
- `-c, --command CMD`: Command to execute on the remote machine
- `-I, --interactive`: Enter interactive job creation mode
- `-d, --debug`: Enable debug mode
- `-q, --quiet`: Suppress progress output
- `-j, --job-file FILE`: Load job definition from file
- `-s, --save-job FILE`: Save job definition to file for later use
- `-p, --parallel N`: Run up to N jobs in parallel (default: 1)
- `-w, --wait`: Wait for all jobs to complete before exiting
- `--help`: Show help message
- `-v, --version`: Show version information

### Simple Example
```bash
# Run a command on remote machine
vohvelo.sh -h user@host -c "ls -la"

# Process a file and get results
vohvelo.sh -i input.txt -o output.txt -h user@host -c "sort input.txt > output.txt"
```

## 🔧 Advanced Usage

### Interactive Mode

The interactive mode (`-I` or `--interactive`) provides a guided interface for creating and running jobs:

```
Vohvelo Interactive Job Creator v1.0.0
-----------------------------------

Job #1:

Remote Host
Format: user@hostname (e.g., jetson@192.168.1.100)
This is the remote machine where the command will be executed.
Remote host: jetson@192.168.31.217

Input Files
These files will be copied to the remote machine before execution.
Examples: video.mkv (for transcoding), data.csv (for processing)
Press enter without typing anything when done adding files.
Input file #1: 

Output Files
These files will be copied back after command execution.
Examples: output.mp4 (transcoded video), results.txt (command output)
Press enter without typing anything when done adding files.
Output file #1: list.txt
Output file #2: 

Remote Command
The command to execute on the remote machine.
Examples:
  ls -la > list.txt              (list directory contents)
  ffmpeg -i in.mkv out.mp4       (transcode video)
  python3 script.py data.csv     (process data)
Command: ls > list.txt

Job created:
vohvelo.sh \
  -o "list.txt" \
  -h "jetson@192.168.31.217" \
  -c "ls > list.txt"
```

**Features:**

1. **Step-by-Step Job Creation**
   - Guided prompts for each component
   - Clear examples and explanations
   - Input validation and error handling
   - Command syntax assistance

2. **Multiple Job Support**
   ```
   Add another job? [y/N]: 
   
   Job Queue Summary
   ----------------
   Job #1: pending
   
   Run jobs now? [Y/n]: 
   ```
   - Create multiple jobs in one session
   - Review job queue before execution
   - Execute all jobs sequentially

3. **Real-Time Feedback**
   ```
   Running Job #1
   SSH connection established
   Starting remote process...
   Remote process completed
   
   Command output:
   [Directory listing appears here]
   
   Copying result from remote host...
   File retrieved successfully
   ```
   - See command output in real-time
   - Track job progress
   - View execution results

4. **Job Status Tracking**
   ```
   Final Job Status
   ---------------
   Job #1: completed
   ```
   - Monitor job completion
   - See final execution status
   - Handle multiple job results

### Job Queue Management

The script provides robust job queue management:

1. **Job Creation**
   ```bash
   # Interactive job creation with save
   vohvelo.sh --interactive -s jobs.json
   ```

2. **Job Execution**
   ```bash
   # Load and run saved jobs
   vohvelo.sh -j jobs.json -p 4 -w
   ```

3. **Job Features**
   - Save jobs for later execution
   - Run multiple jobs in parallel
   - Wait mode for continuous execution
   - Job status tracking and reporting
   - Command output capture and display

### Video Processing

1. Basic Video Transcoding
   ```bash
   vohvelo.sh -i video.mkv -o output.mp4 -h user@host \
     -c "ffmpeg -i video.mkv -c:v libx264 -preset medium output.mp4"
   ```

2. Complex Video Processing
   ```bash
   vohvelo.sh -i input.mp4 -o output.mp4 -h user@host \
     -c 'ffmpeg -i input.mp4 -vf "scale=1920:1080,fps=30" \
     -c:v libx264 -preset slow -crf 22 \
     -c:a aac -b:a 128k output.mp4'
   ```

3. Batch Processing with Debug Info
   ```bash
   vohvelo.sh -d \
     -i video1.mp4 -i video2.mp4 \
     -o processed1.mp4 -o processed2.mp4 \
     -h user@host \
     -c './process_videos.sh video1.mp4 video2.mp4'
   ```

### Data Processing

1. Text File Processing
   ```bash
   vohvelo.sh \
     -i data.csv -i config.json \
     -o results.csv \
     -h user@host \
     -c "python3 process_data.py data.csv config.json results.csv"
   ```

2. Image Processing
   ```bash
   vohvelo.sh \
     -i "input folder/image.jpg" \
     -o "processed/result.png" \
     -h user@host \
     -c "convert 'input folder/image.jpg' -resize 50% 'processed/result.png'"
   ```

### Multiple Files

1. Merge and Process
   ```bash
   vohvelo.sh \
     -i part1.txt -i part2.txt -i part3.txt \
     -o merged.txt -o stats.json \
     -h user@host \
     -c "cat part*.txt > merged.txt && analyze_text.py merged.txt stats.json"
   ```

2. Parallel Processing
   ```bash
   vohvelo.sh \
     -i dataset.csv -i script.R \
     -o plot1.pdf -o plot2.pdf -o stats.txt \
     -h user@host \
     -c "Rscript script.R dataset.csv"
   ```

### Debug Mode

Enable detailed progress information:
```bash
vohvelo.sh -d \
  -i large_file.dat -o results.dat \
  -h user@host \
  -c "./process_data large_file.dat results.dat"
```

## 📚 Command Reference

### Command Structure
```bash
vohvelo.sh [options]

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
```

### Path Handling
- Relative paths are resolved from the current directory
- Absolute paths are preserved
- Spaces in paths are handled automatically
- Remote paths are managed in a temporary directory

## 🎯 Use Cases

### 1. High-Performance Computing
Offload intensive computations to more powerful machines:
```bash
vohvelo.sh \
  -i dataset.h5 -i analysis.py \
  -o results.h5 -o plots.pdf \
  -h user@powerful-server \
  -c "python3 analysis.py dataset.h5 results.h5 plots.pdf"
```

### 2. Media Processing
Transform media files using remote resources:
```bash
vohvelo.sh \
  -i raw.mkv \
  -o compressed.mp4 -o thumbnail.jpg \
  -h user@media-server \
  -c 'ffmpeg -i raw.mkv -vf "thumbnail" thumbnail.jpg && \
   ffmpeg -i raw.mkv -c:v libx264 compressed.mp4'
```

### 3. Distributed Processing
Process parts of data on different machines:
```bash
vohvelo.sh \
  -i chunk1.dat -i processor.py \
  -o processed1.dat \
  -h user@compute-node-1 \
  -c "python3 processor.py chunk1.dat processed1.dat"
```

## 🔄 Future Improvements

1. **Parallel Job Execution**
   - Implement true parallel job execution
   - Add job dependency management
   - Add resource allocation and management

2. **Job Management**
   - Add job templates
   - Add job history and logging
   - Add job status persistence
   - Add job retry mechanisms

3. **Remote Host Management**
   - Add host configuration files
   - Add host groups for job distribution
   - Add host health checking
   - Add host resource monitoring

4. **Security Enhancements**
   - Add SSH key management
   - Add support for SSH config files
   - Add connection pooling
   - Add connection encryption options

5. **User Interface**
   - Add progress bars for file transfers
   - Add real-time job monitoring
   - Add web interface option
   - Add remote process monitoring

6. **Error Handling**
   - Add automatic retry for failed transfers
   - Add network failure recovery
   - Add timeout management
   - Add cleanup verification

7. **Performance**
   - Add file compression options
   - Add bandwidth management
   - Add caching mechanisms
   - Add delta transfers

8. **Integration**
   - Add CI/CD pipeline integration
   - Add container support
   - Add cloud provider support
   - Add scheduling system integration

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit your changes
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. Push to your branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE.txt` for more information.

---

**Project Link**: [https://github.com/bicubico/vohvelo](https://github.com/bicubico/vohvelo)
