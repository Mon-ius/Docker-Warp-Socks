#!/bin/bash

ARCH="linux/amd64" # Expected `linux/amd64``, `linux/arm64`, `linux/arm`, and `linux/s390x`;

if [ -n "$1" ] 
then
    ARCH=$1
fi

sudo docker run --privileged --platform="${ARCH}" --restart=always -itd \
    --name warp_socks -e LOG=1 \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --cap-add NET_ADMIN --cap-add SYS_MODULE \
    -p 9091:9091 \
    -v /lib/modules:/lib/modules \
    monius/docker-warp-socks