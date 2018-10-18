# nginx-rtmp-ffmpeg

An nginx-rtmp container for encoding streams with ffmpeg, and pushing to other streaming servers, e.g. twitch.tv

This is useful if you would like to offload the CPU cost of expensive video compression,
allowing you to stream relatively uncompressed video at high bitrates on a fast, local network,
and have a different PC encode and publish the stream to the remote server.

## required environment variables

- `STREAM_KEY`: the stream key required by your streaming service, e.g. `live_x01234567890123456789x`

## optional environment variables

- `BITRATE`: the bitrate, in Kbps, to output (ensure your internet upstream can handle this value), default `2500`
- `BUFSIZE`: the bufsize, in Kbps, default `(BITRATE + 128) / 3`
- `RESOLUTION` the resolution to output, default `1280x720`
- `PRESET` the [x264 preset](https://trac.ffmpeg.org/wiki/Encode/H.264#Preset) to encode with, default `veryfast`
- `PROFILE` the x264 profile to use, default `high`
- `FRAMERATE` the framerate to output, default `30`
- `BFRAMES` the number of [B-Frames](https://en.wikipedia.org/wiki/Video_compression_picture_types) to use, default `3`
- `THREADS` the number of CPU threads to use for encoding, default `0` for auto
- `SCALER` the [x264 scaler](https://ffmpeg.org/ffmpeg-scaler.html) to use, default `area` (best for downsampling)
- `RC_LOOKAHEAD` the number of frames to lookahead for rate control, default `FRAMERATE / 3`
- `INGEST` the streaming service ingest server, default `rtmp://live-jfk.twitch.tv/app`
- `STREAM_KEY_2`: the stream key for a second streaming service
- `INGEST_2` a second streaming service ingest server, default none

The variables you set will be assembled into the following ffmpeg arguments:

```
-s ${RESOLUTION} -c:v libx264 -preset ${PRESET} -profile:v ${PROFILE} -r ${FRAMERATE} -g ${FRAMERATE_2X} \
-x264-params \"bitrate=${BITRATE}:vbv_maxrate=${BITRATE}:vbv_bufsize=${BUFSIZE}:threads=${THREADS}:bframes=${BFRAMES}:rc_lookahead=${RC_LOOKAHEAD}:keyint=${FRAMERATE_2X}:min-keyint=${FRAMERATE_2X}:nal_hrd=cbr:scenecut=0:rc=cbr:force-cfr=1\" -sws_flags ${SCALER} -pix_fmt yuv420p -c:a copy -f flv -strict normal
```

If you prefer to customize the ffmpeg arguments, you can instead set the `FFMPEG_ARGS` environment variable, in which case none of the other optional environment variables will be used.

## tips

You can see a list of Twitch suggested settings and ingest endpoints at [stream.twitch.tv](https://stream.twitch.tv/), and you can validate your configuration is proper and stable at [inspector.twitch.tv](https://inspector.twitch.tv).

When selecting your options, be aware that presets from `veryfast` and above noticeably lower picture quality. For more information about stream quality, read [https://streamquality.report](https://streamquality.report).

## standalone examples

simplified:
```
docker run --rm -it -p 1935:1935 -e STREAM_KEY=live_x01234567890123456789x \
  shamelesscookie/nginx-rtmp-ffmpeg:latest
```

customized:
```
docker run --rm -it -p 1935:1935 -e STREAM_KEY=live_x01234567890123456789x -e THREADS=0 \
   -e BITRATE=2500 -e RESOLUTION=1280x720 -e PRESET=veryfast -e FRAMERATE=30 -e PROFILE=high \
   -e BFRAMES=3 -e INGEST=rtmp://live-jfk.twitch.tv/app shamelesscookie/nginx-rtmp-ffmpeg:latest
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
      - BUFSIZE=876
      - RESOLUTION=1280x720
      - PRESET=veryfast
      - FRAMERATE=30
      - PROFILE=high
      - THREADS=0
      - BFRAMES=3
      - SCALER=area
      - RC_LOOKAHEAD=10
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
- Bitrate: `50000` or `100000` or `150000` (depending on your local network)
- Keyframe Interval: `2`
- Preset: `High Quality`
- Profile: `high`
- B-Frames: `0`