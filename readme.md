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

The main limiting factor for `RESOLUTION`, `FRAMERATE`, and `PRESET` is CPU power. A rough way to estimate how much CPU power a given setting will take, multiply the resolution and framerate, and then multiply by the following values to get the total MHz  (sum of all cores):
 * superfast: x0.1
 * veryfast: x0.2
 * faster: x0.3
 * fast: x0.4
 * medium: x0.5

Examples:
 * 1080p60 at medium: 1080 x 60 x 0.5 = 32400MHz (fast hexa-core CPU)
 * 1080p60 at veryfast: 1080 x 60 x 0.2 = 12960MHz (average quad-core CPU)
 * 1080p30 at fast: 1080 x 30 x 0.4 = 12960MHz (average quad-core CPU)
 * 720p60 at faster: 720 x 60 x 0.3 = 12960MHz (average quad-core CPU)
 * 720p30 at veryfast: 720 x 30 x 0.2 = 4320MHz (average dual-core CPU)

If you monitor OBS Stats (from the View menu > Stats), look for:

 * **rendering lag**: GPU is overloaded - try using a framerate limiter such as [RivaTuner Statistics Server](https://www.guru3d.com/files-details/rtss-rivatuner-statistics-server-download.html) to cap framerate at 60fps (60Hz or 120Hz monitor) or 72fps (144Hz monitor).
 * **encoding lag**: CPU is overloaded - ensure you are using a low-overhead codec such as NVENC. AMD users, use an easier x264 profile such as veryfast or ultrafast
 * **dropped frames**: network is choked - lower your bitrate

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
- Keyframe Interval: `0`
- Preset: `Default`
- Profile: `high`