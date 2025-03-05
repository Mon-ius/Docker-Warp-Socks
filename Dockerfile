FROM alpine:3.21

LABEL maintainer="M0nius <m0niusplus@gmail.com>" \
    alpine-version="3.21.3" \
    org.opencontainers.image.title="Docker-Warp-Socks" \
    org.opencontainers.image.description="Connet to CloudFlare WARP, exposing `socks5` proxy all together." \
    org.opencontainers.image.authors="M0nius <m0niusplus@gmail.com>" \
    org.opencontainers.image.vendor="M0nius Acc" \
    org.opencontainers.image.version="4.1.0" \
    org.opencontainers.image.url="https://hub.docker.com/r/monius/docker-warp-socks" \
    org.opencontainers.image.source="https://github.com/Mon-ius/Docker-Warp-Socks" \
    org.opencontainers.image.base.name="docker.io/monius/docker-warp-socks"

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" | tee -a /etc/apk/repositories

RUN apk update && apk upgrade \
    && apk add --no-cache curl openssl sing-box jq \
    && rm -rf /var/cache/apk/*

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

CMD ["rws-cli"]
