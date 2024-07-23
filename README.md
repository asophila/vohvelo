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
    Vohvelo [βo̞ʰ ve̞lo̞ʰ] aims to be a simple and widely usable tool to run processes on a remote machine. Although is quite simple to do just by SSH'ing into another machine and running a process, that manual work of copying, waiting the process to finish and bringing the results back (and cleaning up the remote host) can be a little bit frustrating.
    <br />
    The original use case comes from trying to transcode from x265 in a Raspberry Pi, failing to do so, and trying to automate the outsourced process into my main computer.
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
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

https://user-images.githubusercontent.com/5770504/173208139-d86893e6-f79f-4e42-938e-6647acd77cce.mp4


Run your process (with the files needed) on another machine and bring back the results.

<p align="right">(<a href="#top">back to top</a>)</p>



### Built With Bash

<p align="right">(<a href="#top">back to top</a>)</p>


<!-- GETTING STARTED -->
## Getting Started

Just clone the project and run it in your local machine.
The process to be run must be already installed on the remote machine.

### Prerequisites

What you'll need:
* bash
* ssh
* scp

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/asophila/vohvelo.git
   ```
2. Done

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

Vohvelo now supports various options for enhanced functionality::
```sh
./vohvelo.sh [options] <remote user> <remote host> <remote command> <input file(s)> <output file>
```
### Options:

```
-c, --config <file>: Specify a configuration file (default: ~/.vohvelo.conf)
-l, --log <file>: Specify a log file (default: vohvelo.log)
-b, --bandwidth <limit>: Set bandwidth limit for file transfers (e.g., 1m for 1MB/s)
-z, --compress: Enable compression for file transfers
-r, --retries <num>: Set number of retries for network operations (default: 3)
-p, --parallel <num>: Set number of parallel executions (default: 1)
-h, --help: Display help message
```

Example:
Suppose we have multiple video files on a low power machine, a Raspberry Pi or something like that, and we need to do the transcoding from x265 to x264 to make it easier for the Rpi to play back those files. 
The transcoding could take many hours on the Raspberry, but only a few minutes on another machine in the network. 
To send the video files, ask the other machine to transcode, and send back the transcoded files, you would use something like:

```sh
./vohvelo.sh -z -p 4 remote_user 192.168.0.45 "ffmpeg -i '\$1' -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k '\$2'" morbius.mkv avengers.mkv thor.mkv output_%d.mp4
```

This will:
* Copy the original files to the remote machine using the user and host provided
* Trigger the ffmpeg transcoding process for each file (up to 4 in parallel)
* Use compression for file transfers
* Wait for the transcoding to finish
* Copy the resulting files back to the local machine
* Cleanup the remote folders

<p align="right">(<a href="#top">back to top</a>)</p>


<!-- ROADMAP -->
## Roadmap

- [x] Process files with full input and output paths
- [x] Accept filenames containing spaces
- [x] Add Parallel processing support
- [x] Compress files for transfer
- [x] Add logging system
- [x] Add config files for default options
- [x] Add bandwitdht limits
- [x] Accept any process (with arguments) as an input

See the [open issues](https://github.com/github_username/repo_name/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#top">back to top</a>)</p>



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

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Your Name - [@asophila](https://lile.cl/asophila) - asophila ARR0BA pm.me

Project Link: [https://github.com/asophila/vohvelo](https://github.com/asophila/vohvelo)

<p align="right">(<a href="#top">back to top</a>)</p>


<p align="right">(<a href="#top">back to top</a>)</p>
