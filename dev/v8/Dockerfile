FROM alpine:3.24

LABEL maintainer="M0nius <m0niusplus@gmail.com>" \
    alpine-version="3.24.1" \
    org.opencontainers.image.title="Docker-Warp-Socks" \
    org.opencontainers.image.description="Connect to Cloudflare WARP with a mixed SOCKS5 and HTTP proxy." \
    org.opencontainers.image.authors="M0nius <m0niusplus@gmail.com>" \
    org.opencontainers.image.vendor="M0nius Acc" \
    org.opencontainers.image.version="8.0.0" \
    org.opencontainers.image.url="https://hub.docker.com/r/monius/docker-warp-socks" \
    org.opencontainers.image.source="https://github.com/Mon-ius/Docker-Warp-Socks" \
    org.opencontainers.image.base.name="docker.io/monius/docker-warp-socks"

RUN apk update && apk upgrade \
    && apk add --no-cache ca-certificates curl openssl jq tar gcompat \
    && rm -rf /var/cache/apk/*

RUN set -e; \
    cd /tmp; \
    case $(arch) in \
        x86_64)  ARCH='amd64' ;; \
        aarch64) ARCH='arm64' ;; \
        armv7l)  ARCH='armv7' ;; \
        armv6l)  ARCH='armv6' ;; \
        arm)     ARCH='armv7' ;; \
        ppc64le) ARCH='ppc64le' ;; \
        s390x)   ARCH='s390x' ;; \
        riscv64) ARCH='riscv64' ;; \
        *)       echo "Unsupported architecture $(arch)" && exit 1 ;; \
    esac; \
    echo "Resolving latest sing-box 1.14.x stable for linux-${ARCH}..."; \
    RELEASE_URL=$(curl -fsSL --compressed --connect-timeout 15 --max-time 60 "https://api.github.com/repos/SagerNet/sing-box/releases?per_page=100" | \
        jq -r --arg arch "$ARCH" '[.[] | select(.prerelease == false and .draft == false) | select(.tag_name | test("^v1\\.14\\.[0-9]+$"))] | sort_by(.tag_name | ltrimstr("v") | split(".") | map(tonumber)) | last | .assets[]? | select(.name | endswith("-linux-" + $arch + ".tar.gz")) | .browser_download_url') || RELEASE_URL=""; \
    if [ -z "$RELEASE_URL" ] || [ "$RELEASE_URL" = "null" ]; then \
        echo "No 1.14.x release resolved via API, falling back to pinned v1.14.2..."; \
        RELEASE_URL="https://github.com/SagerNet/sing-box/releases/download/v1.14.2/sing-box-1.14.2-linux-${ARCH}.tar.gz"; \
    fi && \
    echo "Downloading from: ${RELEASE_URL}" && \
    curl -fsSL "$RELEASE_URL" -o singbox.tar.gz && \
    tar xzf singbox.tar.gz --strip-components=1 && \
    mv sing-box /usr/bin/sing-box && \
    chmod +x /usr/bin/sing-box && \
    sing-box version && \
    mkdir -p /etc/sing-box && \
    rm -rf /tmp/*

COPY --chmod=755 entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

CMD ["rws-cli-v8"]
