# Docker-Warp-Socks

A lightweight Docker image, designed for easy connection to CloudFlare WARP, exposing `socks5` proxy all together.

[![Docker Pulls](https://badgen.net/docker/pulls/monius/docker-warp-socks)](https://hub.docker.com/r/monius/docker-warp-socks)

Multiple platform support: `linux_386`(\*86), `linux_amd64`(x86_64 | amd64), `linux_arm64`(aarch64 | arm64), `linux_armv7`(arm\*);

## Why to use

The official `warp-cli` only support amd64 machines, and its [guide](https://github.com/cloudflare/cloudflare-docs/pull/7644) is prone to causing potential connection loss risks on remote machines. It is recommended to experiment with fresh installations within a docker container, or you have to reboot it via the panel.

With any existed running proxy service, it acts just like a plugin that helps unlock public content such as `ChatGPT`, `Google Scholar`, and `Netflix`. No necessary to have any knowledge of `CloudFlare`, `Warp`, `WireGuard`, and `WGCF` before using this image.

## Usage

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
    monius/Docker-Warp-Socks
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
    monius/Docker-Warp-Socks
```

### Source

https://github.com/Mon-ius/Docker-Warp-Socks

### Credits

- [warp](https://developers.cloudflare.com/warp-client/get-started/linux/)
- [wgcf-docker](https://github.com/Neilpang/wgcf-docker)
- [wireguard-socks-proxy](https://github.com/ispmarin/wireguard-socks-proxy)
