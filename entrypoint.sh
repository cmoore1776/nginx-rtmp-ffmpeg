#!/bin/sh
set -e

FRAMERATE_2X=$(($FRAMERATE * 2))

cat >/etc/nginx/nginx.conf << EOF
error_log logs/error.log debug;

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
      exec ffmpeg -i "rtmp://127.0.0.1/livein/${STREAM_KEY}" -b:v ${BITRATE}K -bufsize ${BITRATE}K -s ${RESOLUTION} -c:v libx264 -preset ${PRESET} -profile:v ${PROFILE} -level:v ${LEVEL} -r ${FRAMERATE} -g ${FRAMERATE_2X} -keyint_min ${FRAMERATE} -x264opts "nal-hrd=cbr:force-cfr=1:keyint=${FRAMERATE_2X}:min-keyint=${FRAMERATE_2X}:no-scenecut" -sws_flags lanczos -pix_fmt yuv420p -c:a copy -f flv -threads ${THREADS} -strict normal "rtmp://127.0.0.1/liveout/${STREAM_KEY}";
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
