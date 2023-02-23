[![Docker Pulls](https://badgen.net/docker/pulls/monius/docker-warp-socks)](https://hub.docker.com/r/monius/docker-warp-socks)

## Docker-Warp-Socks

The official `warp-cli` exclusively supports amd64 machines, and its [guide](https://github.com/cloudflare/cloudflare-docs/pull/7644) is prone to causing potential connection loss risks on remote machines. It is recommended to experiment with fresh installations within a docker container. Otherwise, you will be forced to start it via the panel.

It is not necessary to have any knowledge of `Cloudflare`, `Warp`, `wireguard`, and `wgcf` before using this image. All that is required is the ability to unblock content, such as `chatgpt`, `google scholar`, and `netflix`, using certain existing services on your remote machine.

### Usage

#### Docker cli

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

#Host
curl -4 --proxy socks5h://127.0.0.1:9091 https://www.cloudflare.com/cdn-cgi/trace 
curl -6 --proxy socks5h://127.0.0.1:9091 https://www.cloudflare.com/cdn-cgi/trace 

# or connect to container
docker exec -it warp_socks /bin/bash
curl -4 --proxy socks5h://127.0.0.1:9091 https://www.cloudflare.com/cdn-cgi/trace 
curl -6 --proxy socks5h://127.0.0.1:9091 https://www.cloudflare.com/cdn-cgi/trace 

# See `warp=on` means success.
```

#### Advanced

It will also recognize the prepared `warp.conf` and `danted.conf` if they are located in `~/wireguard/`.

``` bash
docker run --privileged --restart=always -itd \
    --name warp_socks \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --cap-add NET_ADMIN --cap-add SYS_MODULE \
    -p 9091:9091 \
    -v /lib/modules:/lib/modules \
    -v ~/wireguard/:/etc/wireguard/:ro \
    monius/Docker-Warp-Socks
```

#### Source

https://github.com/Mon-ius/Docker-Warp-Socks

#### Credits

- [warp](https://developers.cloudflare.com/warp-client/get-started/linux/)
- [wgcf-docker](https://github.com/Neilpang/wgcf-docker)
- [wireguard-socks-proxy](https://github.com/ispmarin/wireguard-socks-proxy)
