# Giftwrap

A Node.js app that watches a folder for videos in formats and wrappers that nobody can use (MKV, 2t, etc.) and transmuxes them to MP4 so that people can actually do something with them (read: AirPlay to Apple TV.)

# Requirements

- Node.js
- ffmpeg
- libx264
- Ruby (installed on Mac already)

## Installation

### Node.js
Install Node.js by downloading the Mac installer from (nodejs.org)[http://nodejs.org]. 

### ffmpeg & libx264
Download binary for ffmpeg from http://ffmpeg.org/download.html

### NPM Dependencies
NPM is bundled with Node so you do not have to install it. 

You will need to install the NPM modules for the app by running `npm install` inside the app directory.

## Usage
To run the app, open Terminal and go to the folder then run:
`node application`

By default, the `./process` folder is what is watched for new video files. You can move video files there and they will be automatically processed and output into the `./output` directory as H.264 MP4s.

For seamless autonomy, read below how to automatically get video files from your torrent client to the process folder.

## Transmission Setup
It is recommended you use (Transmission)[http://transmissionbt.com] as a bit torrent client because on download completion it will run a ruby script to move video files into the processing folder automatically.

![ScreenShot1](https://raw.github.com/adr-enal-in/giftwrap/master/docs/images/transmission-screenshot.png)

![ScreenShot2](https://raw.github.com/adr-enal-in/giftwrap/master/docs/images/transmission-screenshot2.png)


## How It Works

The main purpose of the app is to just ditch the idiotic MKV wrapper format and copy the video content to MP4. This _should_ require no video quality loss or re-encoding but will have to convert AC3 audio streams to AAC. Because there is very little encoding going on it runs really fast and is probably more limited by I/O than CPU.

Any good Bittorrent client (Transmission) will run scripts that can move finished files into the processing directory so everything happens automatically.
