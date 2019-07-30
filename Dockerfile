# Dockerfile for a simple Nginx stream replicator
FROM alpine:3.10

ENV USER nginx
RUN adduser -s /sbin/nologin -D -H ${USER}

RUN \
  apk update && \
  apk upgrade && \
  apk add \
    nginx-mod-rtmp \
    ffmpeg && \
  rm -rf /var/cache/apk/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN chown nginx /etc/nginx/nginx.conf

COPY entrypoint.sh /
RUN chmod +x entrypoint.sh

USER ${USER}
EXPOSE 1935

CMD ["./entrypoint.sh"]
