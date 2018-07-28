# nginx-rtmp-ffmpeg

An nginx-rtmp container for encoding streams with ffmpeg, and pushing to other streaming servers, e.g. twitch.tv

This is useful if you would like to offload the CPU cost of expensive video compression,
allowing you to stream relatively uncompressed video at high bitrates on a fast, local network,
and have a different PC encode and publish the stream to the remote server.

## required environment variables

- `STREAM_KEY`: the stream key required by your streaming service, e.g. `live_x01234567890123456789x`
- `BITRATE`: the bitrate, in Kbps, to output (ensure your internet upstream can handle this value), e.g. `2500`
- `RESOLUTION` the resolution to output, e.g. `1280x720`
- `PRESET` the [x264 preset](http://dev.beandog.org/x264_preset_reference.html) to encode with, e.g. `veryfast`
- `PROFILE` the x264 profile to use, e.g. `high`
- `LEVEL` the [x264 level](https://en.wikipedia.org/wiki/H.264/MPEG-4_AVC#Levels) to use, e.g. `31`
- `FRAMERATE` the framerate to output, e.g. `30`
- `THREADS` the number of CPU threads to use for encoding, e.g. `0` for auto
- `INGEST` the streaming service ingest server, e.g. `rtmp://live-jfk.twitch.tv/app`

You can see a list of Twitch suggested settings and ingest endpoints at [stream.twitch.tv](https://stream.twitch.tv/), and you can validate your configuration is proper and stable at [inspector.twitch.tv](https://inspector.twitch.tv).

## tips

The main limiting factor for `BITRATE` is your upload speed. Use a site such as [www.speedtest.net](http://www.speedtest.net) to validate your upload speed, and don't exceed 80% of that number. For example, if your upload speed is 5Mbit (5000Kbit) then don't use a bitrate above 4000). Use Twitch's recommended settings from [stream.twitch.tv](https://stream.twitch.tv/).

The main limiting factor for `RESOLUTION`, `FRAMERATE`, and `PRESET` (and to a small extent, `BITRATE`) is CPU power. A rough way to estimate how much CPU power a given setting will take, use the table below, and consider that a value of 50 = one modern CPU core at 4GHz:

| resolution | fps | slow | medium | fast | faster | veryfast | superfast | 
|------------|-----|------|--------|------|--------|----------|-----------| 
| 1920x1080  | 60  | 635  | 460    | 365  | 305    | 215      | 160       | 
| 1920x1080  | 30  | 320  | 230    | 185  | 155    | 110      | 80        | 
| 1280x720   | 60  | 395  | 280    | 230  | 195    | 145      | 120       | 
| 1280x720   | 30  | 200  | 140    | 115  | 100    | 75       | 60        | 

or, in terms of numbers of 4GHz CPU cores:

| resolution | fps | slow | medium | fast | faster | veryfast | superfast | 
|------------|-----|------|--------|------|--------|----------|-----------| 
| 1920x1080  | 60  | 12.7 | 9.2    | 7.3  | 6.1    | 4.3      | 3.2       | 
| 1920x1080  | 30  | 6.4  | 4.6    | 3.7  | 3.1    | 2.2      | 1.6       | 
| 1280x720   | 60  | 7.9  | 5.6    | 4.6  | 3.9    | 2.9      | 2.4       | 
| 1280x720   | 30  | 4    | 2.8    | 2.3  | 2      | 1.5      | 1.2       | 

When selecting your options, be aware that presets from `veryfast` and above noticably lower picture quality:

![1080p60_quality](https://scratch.christianmoore.me/streamquality/1080p60_quality.png)

## standalone example

```
docker run --rm -it -p 1935:1935 -e STREAM_KEY=live_x01234567890123456789x \
   -e BITRATE=2500 -e RESOLUTION=1280x720 -e PRESET=veryfast -e FRAMERATE=30 -e THREADS=0 \
   -e PROFILE=high -e LEVEL=31 -e INGEST=rtmp://live-jfk.twitch.tv/app shamelesscookie/nginx-rtmp-ffmpeg:latest
```

## docker-compose example

```
version: '2'
services:
  nginx-rtmp-ffmpeg:
    container_name: nginx-rtmp-ffmpeg
    image: shamelesscookie/nginx-rtmp-ffmpeg:latest
    network_mode: host
    ports:
      - 1935
    restart: always
    environment:
      - STREAM_KEY=live_x01234567890123456789x
      - BITRATE=2500
      - RESOLUTION=1280x720
      - PRESET=veryfast
      - FRAMERATE=30
      - PROFILE=high
      - LEVEL=31
      - THREADS=0
      - INGEST=rtmp://live-jfk.twitch.tv/app
```

## source PC settings

Configure your streaming software to output to `rtmp://<docker-server>:1935/livein`
Make sure you include your stream key in your streaming software as well, e.g. for OBS:

- File > Settings > Stream
- Stream Type: `Custom Streaming Server`
- URL: `rtmp://<docker-server>:1935/livein`, e.g. `rtmp://mydockerbox:1935/livein`
- Stream key: `<your-stream-key>`

Then use video settings that are very high in quality and low in overhead, e.g. for nVidia video cards:

- File > Settings > Output > Streaming
- Encoder: `NVENC H.264`
- Rate Control: `CBR`
- Bitrate: `50000`, or some other very high bitrate for local stream
- Keyframe Interval: `2`
- Preset: `Default`
- Profile: `high`