#!/bin/sh
set -e

if [ -z ${BITRATE+x} ]; then BITRATE=2500; fi
if [ -z ${BUFSIZE+x} ]; then BUFSIZE=$((($BITRATE + 3 + 1) / 3)); fi
if [ -z ${RESOLUTION+x} ]; then RESOLUTION=1280x720; fi
if [ -z ${PRESET+x} ]; then PRESET=veryfast; fi
if [ -z ${PROFILE+x} ]; then PROFILE=high; fi
if [ -z ${FRAMERATE+x} ]; then FRAMERATE=30; fi
if [ -z ${BFRAMES+x} ]; then BFRAMES=3; fi
if [ -z ${THREADS+x} ]; then THREADS=0; fi
if [ -z ${SCALER+x} ]; then SCALER=lanczos; fi
if [ -z ${RC_LOOKAHEAD+x} ]; then RC_LOOKAHEAD=$((($FRAMERATE + 3 - 1) / 3)); fi
if [ -z ${INGEST+x} ]; then INGEST="rtmp://live-jfk.twitch.tv/app"; fi
if [ "${INGEST_2}" ]; then INGEST_STATEMENT_2="push ${INGEST_2}/${STREAM_KEY_2};"; fi
INGEST_STATEMENT="push ${INGEST}/${STREAM_KEY};"
FRAMERATE_2X=$(($FRAMERATE * 2))

echo BITRATE=$BITRATE
echo BUFSIZE=$BUFSIZE
echo RESOLUTION=$RESOLUTION
echo PRESET=$PRESET
echo PROFILE=$PROFILE
echo FRAMERATE=$FRAMERATE
echo BFRAMES=$BFRAMES
echo THREADS=$THREADS
echo SCALER=$SCALER
echo RC_LOOKAHEAD=$RC_LOOKAHEAD
echo INGEST=$INGEST
echo STREAM_KEY=$STREAM_KEY

if [ -z ${FFMPEG_ARGS+x} ]; then FFMPEG_ARGS="-s ${RESOLUTION} -r ${FRAMERATE} -c:v libx264 -preset ${PRESET} -profile:v ${PROFILE} -g ${FRAMERATE_2X} -x264-params \"bitrate=${BITRATE}:vbv_maxrate=${BITRATE}:vbv_bufsize=${BUFSIZE}:threads=${THREADS}:bframes=${BFRAMES}:rc_lookahead=${RC_LOOKAHEAD}:keyint=${FRAMERATE_2X}:min-keyint=${FRAMERATE_2X}:nal_hrd=cbr:scenecut=0:rc=cbr:force-cfr=1\" -sws_flags ${SCALER} -pix_fmt yuv420p -c:a copy -f flv -strict normal"; fi

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
      exec ffmpeg -i "rtmp://127.0.0.1/livein/${STREAM_KEY}" ${FFMPEG_ARGS} "rtmp://127.0.0.1/liveout";
    }

    application liveout {
      live on;
      record off;
      ${INGEST_STATEMENT}
      ${INGEST_STATEMENT_2}
    }
  }
}
EOF

exec nginx -g "pid /tmp/nginx.pid; daemon off;"
