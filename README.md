# vohvelo
<div id="top"></div>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/asophila/vohvelo">
    <img src="images/vohvelo-logo.png" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">VOHVELO</h3>

  <p align="center">
    Vohvelo [βo̞ʰ ve̞lo̞ʰ] is a robust tool for running processes on remote machines. While SSH makes it easy to run commands remotely, Vohvelo automates the entire workflow of copying files, executing processes, and retrieving results, making remote processing seamless and efficient.
    <br />
    The original use case comes from transcoding video from x265 to x264 on a Raspberry Pi, where offloading the process to a more powerful machine significantly reduces processing time.
    <br />
    <a href="https://github.com/bicubico/vohvelo"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/bicubico/vohvelo">View Demo</a>
    ·
    <a href="https://github.com/bicubico/vohvelo/issues">Report Bug</a>
    ·
    <a href="https://github.com/bicubico/vohvelo/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#key-features">Key Features</a></li>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#examples">Examples</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About The Project

https://user-images.githubusercontent.com/5770504/173208139-d86893e6-f79f-4e42-938e-6647acd77cce.mp4

Vohvelo simplifies the process of running tasks on remote machines by handling all the necessary steps:
1. Securely copying input files to the remote machine
2. Executing the process remotely
3. Retrieving the results back to your local machine
4. Cleaning up temporary files on the remote host

### Key Features

- **Robust Error Handling**: Comprehensive error checking and meaningful error messages
- **Path Support**: Handles both relative and absolute paths for input/output files
- **Space-Safe**: Properly handles filenames containing spaces and special characters
- **Secure**: Uses SSH for secure file transfers and remote execution
- **Clean**: Automatically manages temporary files and connections
- **User-Friendly**: Colored output and progress indicators
- **Efficient**: Uses SSH control connections for faster operations

### Built With

- Bash
- SSH/SCP for secure remote operations
- Standard Unix tools

<!-- GETTING STARTED -->
## Getting Started

To get started with Vohvelo, follow these simple steps.

### Prerequisites

The following tools must be installed on your local machine:
* bash
* ssh
* scp
* readlink (for path resolution)
* xxd (for random filename generation)

The process to be run (e.g., ffmpeg) must be installed on the remote machine.

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/asophila/vohvelo.git
   ```
2. Make the script executable
   ```sh
   chmod +x vohvelo.sh
   ```
3. Optionally, move to your PATH
   ```sh
   sudo cp vohvelo.sh /usr/local/bin/vohvelo
   ```

<!-- USAGE -->
## Usage

```sh
vohvelo.sh [options] <input_file> <remote_user> <remote_host> <output_file>
```

### Arguments

- `input_file`: Path to the file to process (supports relative/absolute paths)
- `remote_user`: Username for SSH connection
- `remote_host`: Remote hostname or IP address
- `output_file`: Path for the output file (supports relative/absolute paths)

### Options

- `-h, --help`: Show help message and exit
- `-v, --version`: Show version information and exit

<!-- EXAMPLES -->
## Examples

### Basic Usage
Process a video file on a remote machine:
```sh
./vohvelo.sh "My Video.mkv" user 192.168.0.45 "Processed Video.mp4"
```

### Using Absolute Paths
```sh
./vohvelo.sh /home/user/videos/input.mkv remote_user 192.168.0.45 /home/user/processed/output.mp4
```

### Using Remote Hostname
```sh
./vohvelo.sh video.mkv user media-server.local output.mp4
```

<!-- ROADMAP -->
## Roadmap

- [x] Handle filenames with spaces
- [x] Support full input/output paths
- [x] Add proper error handling
- [ ] Accept any process (with arguments) as input
    - [ ] Recognize filenames in the command
    - [ ] Check if those filenames exist locally
    - [ ] Copy necessary files to remote machine
    - [ ] Identify output filenames
- [ ] Add progress indicators for file transfers
- [ ] Add configuration file support
- [ ] Add parallel processing support

See the [open issues](https://github.com/bicubico/vohvelo/issues) for a full list of proposed features (and known issues).

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<!-- CONTACT -->
## Contact

Your Name - [@asophila](https://lile.cl/asophila) - asophila ARR0BA pm.me

Project Link: [https://github.com/asophila/vohvelo](https://github.com/asophila/vohvelo)

<p align="right">(<a href="#top">back to top</a>)</p>
