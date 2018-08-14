#!/bin/sh
set -e

if [ -z ${BITRATE+x} ]; then BITRATE=2500; fi
if [ -z ${RESOLUTION+x} ]; then RESOLUTION=1280x720; fi
if [ -z ${PRESET+x} ]; then PRESET=veryfast; fi
if [ -z ${PROFILE+x} ]; then PROFILE=high; fi
if [ -z ${FRAMERATE+x} ]; then FRAMERATE=30; fi
if [ -z ${BFRAMES+x} ]; then BFRAMES=3; fi
if [ -z ${THREADS+x} ]; then THREADS=0; fi
if [ -z ${INGEST+x} ]; then INGEST=rtmp://live-jfk.twitch.tv/app; fi

FRAMERATE_2X=$(($FRAMERATE * 2))

if [ -z ${FFMPEG_ARGS+x} ]; then FFMPEG_ARGS="-b:v ${BITRATE}K -bufsize ${BITRATE}K -s ${RESOLUTION} -c:v libx264 -preset ${PRESET} -profile:v ${PROFILE} -r ${FRAMERATE} -g ${FRAMERATE_2X} -keyint_min ${FRAMERATE_2X} -bf ${BFRAMES} -x264-params \"nal-hrd=cbr:force-cfr=1:keyint=${FRAMERATE_2X}:min-keyint=${FRAMERATE_2X}:no-scenecut\" -sws_flags lanczos -pix_fmt yuv420p -c:a copy -f flv -threads ${THREADS} -strict normal"; fi

cat >/etc/nginx/nginx.conf << EOF
error_log logs/error.log debug;
load_module /usr/lib/nginx/modules/ngx_rtmp_module.so;

events {
  worker_connections 1024;
}

rtmp {
  server {
    listen 1935;
    chunk_size 4096;
    max_message 10M;

    application livein {
      live on;
      record off;
      exec ffmpeg -i "rtmp://127.0.0.1/livein/${STREAM_KEY}" ${FFMPEG_ARGS} "rtmp://127.0.0.1/liveout/${STREAM_KEY}";
    }

    application liveout {
      live on;
      record off;
      push $INGEST;
    }
  }
}
EOF

exec nginx -g "pid /tmp/nginx.pid; daemon off;"
