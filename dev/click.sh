#!/bin/dash

_ARCH="linux/amd64" # Expected `linux/amd64``, `linux/arm64`, `linux/arm`, and `linux/s390x`;
_NAME="warp_socks"
_KEY=""
_SOCK_USER=""
_SOCK_PWD=""
_PORT="9091"
_VER="2"

KEY="${7:-$_KEY}"
SOCK_PWD="${6:-$SOCK_PWD}"
SOCK_USER="${5:-$SOCK_USER}"
PORT="${4:-$_PORT}"
VER="${3:-$VER}"
ARCH="${2:-$_ARCH}"
NAME="${1:-$_NAME}"

if [ $1 = "-test" ]; then
    api="$2"

    json="{
    \"key\": \"$3\", \
    \"tos\": \"$4\", \
    \"locale\": \"$5\", \
    \"model\": \"$6\", \
    \"type\": \"$7\", \
    \"referrer\": \"$8\" \
    }"

    curl -X POST -fsSL "$api" \
    -H 'authority: cloudflareclient.com' \
    -H 'host: api.cloudflareclient.com' \
    -H 'User-Agent: okhttp/4.12.1' \
    -H 'accept-encoding: gzip' \
    -H 'accept-language: en-US,en;q=0.9' \
    -H 'content-type: application/json; charset=UTF-8' \
    -H 'connection: Keep-Alive' \
    -H 'origin: https://cloudflareclient.com' \
    -H 'referer: https://warp.plus' \
    -H 'user-agent: okhttp/4.12.1' \
    --compressed \
    --data "$json" > /tmp/warp.dat
else
    sudo docker run --privileged --platform="${ARCH}" --restart=always -itd \
        --name "${NAME}" -e LOG=1 \
        -e WGCF_LICENSE_KEY="${KEY}" \
        -e SOCK_USER="${SOCK_USER}" \
        -e SOCK_PWD="${SOCK_PWD}" \
        --sysctl net.ipv6.conf.all.disable_ipv6=0 \
        --sysctl net.ipv4.conf.all.src_valid_mark=1 \
        --cap-add NET_ADMIN --cap-add SYS_MODULE \
        -p "${PORT}":"9091" \
        -v /lib/modules:/lib/modules \
        "monius/docker-warp-socks:${VER}"
fi