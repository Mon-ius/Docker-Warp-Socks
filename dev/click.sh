#!/bin/bash

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

sudo docker run --privileged --platform="${ARCH}" --restart=always -itd \
    --name "${NAME}" -e LOG=1 \
    -e WGCF_LICENSE_KEY="${KEY}" \
    -e SOCK_USER="${SOCK_USER}" \
    -e SOCK_PWD="${SOCK_PWD}" \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --cap-add NET_ADMIN --cap-add SYS_MODULE \
    -p "${PORT}":"${PORT}" \
    -v /lib/modules:/lib/modules \
    monius/docker-warp-socks