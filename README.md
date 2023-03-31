# Docker-Warp-Socks

[![CI Status](https://github.com/Mon-ius/Docker-Warp-Socks/workflows/build/badge.svg)](https://github.com/Mon-ius/Docker-Warp-Socks/actions?query=workflow:build)
[![CI Status](https://github.com/Mon-ius/Docker-Warp-Socks/workflows/verify/badge.svg)](https://github.com/Mon-ius/Docker-Warp-Socks/actions?query=workflow:verify)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker Pulls](https://flat.badgen.net/docker/pulls/monius/docker-warp-socks?icon=docker)](https://hub.docker.com/r/monius/docker-warp-socks)
[![Visitors](https://api.visitorbadge.io/api/visitors?path=https://github.com/Mon-ius/Docker-Warp-Socks&label=Visitors%20Totay&labelColor=%23808080&countColor=%23ffa31a&style=flat&labelStyle=upper)](https://visitorbadge.io/status?path=https://github.com/Mon-ius/Docker-Warp-Socks)

> A lightweight Docker image, designed for easy connection to CloudFlare WARP, exposing `socks5` proxy all together.

Multi-platform: `linux/amd64`, `linux/arm64`, `linux/arm`, and `linux/s390x`;

## Features

- Automatically install and config CloudFlare WARP Client in Docker
- Enable the access of WARP network from Docker Container's **SOCKS5** port
- Extend accessibility and avoid potential restrictions by using proxy services
- Avoid looping verification in the Midjourney Discord Channel
- Prevent being banned by proxying API calls
- Successfully pre-process the AI WaitList
- Develop apps with warp embedded
- Bypass the New Bing wait-list
- ...

## Why to use

The official `warp-cli` only support amd64 machines, and its [guide](https://github.com/cloudflare/cloudflare-docs/pull/7644) is prone to causing potential connection loss risks on remote machines. It is recommended to experiment with fresh installations within a docker container, or you have to reboot it via the panel.

With any existed running proxy service, it acts just like a plugin that helps unlock public content such as `ChatGPT`, `Google Scholar`, and `Netflix`. No necessary to have any knowledge of `CloudFlare`, `Warp`, `WireGuard`, and `WGCF` before using this image.

## Usage

### Prerequisites

```bash
# in case, you have no docker-ce installed;
curl -fsSL https://get.docker.com | sudo bash
```

### Docker cli

The docker image is built based on `ubuntu:22.04` aka `ubuntu:focal`. It's designed to be robust enough to avoid reboot and platform issues.

```bash
docker run --privileged --restart=always -itd \
    --name warp_socks \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --cap-add NET_ADMIN --cap-add SYS_MODULE \
    -p 9091:9091 \
    -v /lib/modules:/lib/modules \
    monius/docker-warp-socks
```

The above command will create a background service that allows the entire container network to join the dual-stack cloudflare network pool without disconnecting from the host.

Test it

``` bash

# Host
curl --proxy socks5h://127.0.0.1:9091 https://www.cloudflare.com/cdn-cgi/trace 

# See`warp=on` means success. 
```

### Advanced

It will also recognize the prepared `wgcf-profile.conf` and `danted.conf` if they are located in `~/wireguard/`.

``` bash
docker run --privileged --restart=always -itd \
    --name warp_socks \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --cap-add NET_ADMIN --cap-add SYS_MODULE \
    -p 9091:9091 \
    -v /lib/modules:/lib/modules \
    -v ~/wireguard/:/opt/wireguard/:ro \
    monius/docker-warp-socks
```



### Tips

For those who has `amd64` remote machine and don't need to use `docker` to secure network connection, I [suggest](https://github.com/cloudflare/cloudflare-docs/pull/7644) to use the official `warp-cli` as following:

``` bash
# install 
curl "https://pkg.cloudflareclient.com/pubkey.gpg" | sudo gpg --yes --dearmor --output "/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg"
echo "deb [arch=amd64 signed-by="/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg"] "https://pkg.cloudflareclient.com/" focal main" | sudo tee "/etc/apt/sources.list.d/cloudflare-client.list"
apt -y update && apt -y install cloudflare-warp

# run
warp-cli register
warp-cli set-mode proxy
warp-cli set-proxy-port 9091
warp-cli connect

# test
curl --proxy socks5h://127.0.0.1:9091 "https://www.cloudflare.com/cdn-cgi/trace "

# See`warp=on` means success. 
```

### Source

[Docker-Warp-Socks](https://github.com/Mon-ius/Docker-Warp-Socks)

### Credits

- [WireGuard](https://www.wireguard.com/)
- [ViRb3/wgcf](https://github.com/ViRb3/wgcf)
- [Cloudflare WARP](https://developers.cloudflare.com/warp-client/get-started/linux/)
- [Neilpang/wgcf-docker](https://github.com/Neilpang/wgcf-docker)
- [Wireguard-Socks-Proxy](https://github.com/ispmarin/wireguard-socks-proxy)

## Notice of Non-Affiliation and Disclaimer

We are not affiliated, associated, authorized, endorsed by, or in any way officially connected with Cloudflare, or any of its subsidiaries or its affiliates. The official Cloudflare website can be found at https://www.cloudflare.com.

![visitor](https://count.getloli.com/get/@warp-socks?theme=asoul)
