FROM monius/docker-warp-socks:meta
ENV LOG=0

RUN apt-get -qq update \
    && apt-get -qq install dnsmasq shadowsocks-libev \
    && apt-get -qq autoremove --purge && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

CMD ["ss-local", "-c", "/etc/shadowsocks-libev/dws_config.json"]
