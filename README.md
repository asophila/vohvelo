# vohvelo
<div id="top"></div>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/bicubico/vohvelo">
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
   git clone https://github.com/bicubico/vohvelo.git
   ```
2. Done

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

Usage is simple:
```sh
./vohvelo.sh <file to process> <remote user> <remote host> <local output filename>
```

Example:
Suppose we have a video file in a low power machine, a Raspberry Pi or something like that, and we need to do the transcoding from x265 to x264 to make it easier for de Rpi to playback that file.
The transcoding could take many hours in the Raspberry, but only 5 minutes in another machine in the network.
To send the video file and ask the other machine to transcode, and send back the transcoded file would need something like:
```sh
./vohvelo.sh morbius.mkv remote_user 192.168.0.45 morbius.mp4
```
This will:
* Copy the original file to the remote machine using the user and host provided
* Trigger the ffmpeg transcoding process (currently the process is hardcoded, maybe later we could make it run anything)
* Wait for the transcoding to finish
* Copy the resulting file back to the local machine
* Cleanup the remote folders

<p align="right">(<a href="#top">back to top</a>)</p>


<!-- ROADMAP -->
## Roadmap

- [ ] Process files with full input and output paths
- [ ] Accept filenames containing spaces
- [ ] Accept any process (with arguments) as an input
    - [ ] Recognize filenames in the command
    - [ ] Check if those filenames exist as files in the local machine
    - [ ] Copy those files to the remote machine
    - [ ] Identify non existant files in the command as output filenames

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

Your Name - [@bicubico](https://twitter.com/bicubico) - bicubico ARR0BA pm.me

Project Link: [https://github.com/bicubico/vohvelo](https://github.com/bicubico/vohvelo)

<p align="right">(<a href="#top">back to top</a>)</p>


<p align="right">(<a href="#top">back to top</a>)</p>
