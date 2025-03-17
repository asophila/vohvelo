# 🚀 Vohvelo

![Vohvelo Logo](images/vohvelo-logo.png)

> Vohvelo [βo̞ʰ ve̞lo̞ʰ] is a powerful tool for executing processes on remote machines. It automates the entire workflow of file transfers, remote execution, and result retrieval, making distributed processing seamless and efficient.

## 📖 Table of Contents
- [Features](#-features)
- [Installation](#-installation)
- [Basic Usage](#-basic-usage)
- [Advanced Usage](#-advanced-usage)
  - [Video Processing](#video-processing)
  - [Data Processing](#data-processing)
  - [Multiple Files](#multiple-files)
  - [Debug Mode](#debug-mode)
- [Command Reference](#-command-reference)
- [Use Cases](#-use-cases)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **Universal Command Execution**: Run any command on remote machines
- **Multiple File Support**: Handle multiple input and output files
- **Robust Error Handling**: Comprehensive validation and error messages
- **Path Flexibility**: Support for both relative and absolute paths
- **Space-Safe**: Properly handle filenames containing spaces
- **Secure**: Use SSH for secure file transfers and execution
- **Clean**: Automatic temporary file management
- **User-Friendly**: Colored output and progress indicators
- **Efficient**: SSH control connections for faster operations
- **Debug Mode**: Detailed progress information for troubleshooting

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
- readlink
- xxd

## 🚀 Basic Usage

The basic syntax is:
```bash
vohvelo.sh [options] <remote_user> <remote_host> <command> [args...]
```

### Options
- `-h, --help`: Show help message
- `-v, --version`: Show version information
- `-i FILE`: Input file to copy to remote machine
- `-o FILE`: Output file to copy back
- `-d`: Debug mode for detailed progress

### Simple Example
```bash
# Run a command on remote machine
vohvelo.sh user remote-host "ls -la"

# Process a file and get results
vohvelo.sh -i input.txt -o output.txt user remote-host "sort input.txt > output.txt"
```

## 🔧 Advanced Usage

### Video Processing

1. Basic Video Transcoding
   ```bash
   vohvelo.sh -i video.mkv -o output.mp4 user host \
     "ffmpeg -i video.mkv -c:v libx264 -preset medium output.mp4"
   ```

2. Complex Video Processing
   ```bash
   vohvelo.sh -i input.mp4 -o output.mp4 user host \
     'ffmpeg -i input.mp4 -vf "scale=1920:1080,fps=30" \
     -c:v libx264 -preset slow -crf 22 \
     -c:a aac -b:a 128k output.mp4'
   ```

3. Batch Processing with Debug Info
   ```bash
   vohvelo.sh -d \
     -i video1.mp4 -i video2.mp4 \
     -o processed1.mp4 -o processed2.mp4 \
     user host \
     './process_videos.sh video1.mp4 video2.mp4'
   ```

### Data Processing

1. Text File Processing
   ```bash
   vohvelo.sh \
     -i data.csv -i config.json \
     -o results.csv \
     user host \
     "python3 process_data.py data.csv config.json results.csv"
   ```

2. Image Processing
   ```bash
   vohvelo.sh \
     -i "input folder/image.jpg" \
     -o "processed/result.png" \
     user host \
     "convert 'input folder/image.jpg' -resize 50% 'processed/result.png'"
   ```

### Multiple Files

1. Merge and Process
   ```bash
   vohvelo.sh \
     -i part1.txt -i part2.txt -i part3.txt \
     -o merged.txt -o stats.json \
     user host \
     "cat part*.txt > merged.txt && analyze_text.py merged.txt stats.json"
   ```

2. Parallel Processing
   ```bash
   vohvelo.sh \
     -i dataset.csv -i script.R \
     -o plot1.pdf -o plot2.pdf -o stats.txt \
     user host \
     "Rscript script.R dataset.csv"
   ```

### Debug Mode

Enable detailed progress information:
```bash
vohvelo.sh -d \
  -i large_file.dat -o results.dat \
  user host \
  "./process_data large_file.dat results.dat"
```

## 📚 Command Reference

### Command Structure
```bash
vohvelo.sh [options] <remote_user> <remote_host> <command>

Options:
  -h, --help              Show this help message
  -v, --version           Show version information
  -i FILE                 Input file (can be used multiple times)
  -o FILE                 Output file (can be used multiple times)
  -d                      Enable debug mode

Arguments:
  remote_user             Username for SSH connection
  remote_host             Hostname or IP address
  command                 Command to execute remotely
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
  user powerful-server \
  "python3 analysis.py dataset.h5 results.h5 plots.pdf"
```

### 2. Media Processing
Transform media files using remote resources:
```bash
vohvelo.sh \
  -i raw.mkv \
  -o compressed.mp4 -o thumbnail.jpg \
  user media-server \
  'ffmpeg -i raw.mkv -vf "thumbnail" thumbnail.jpg && \
   ffmpeg -i raw.mkv -c:v libx264 compressed.mp4'
```

### 3. Distributed Processing
Process parts of data on different machines:
```bash
vohvelo.sh \
  -i chunk1.dat -i processor.py \
  -o processed1.dat \
  user compute-node-1 \
  "python3 processor.py chunk1.dat processed1.dat"
```

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
