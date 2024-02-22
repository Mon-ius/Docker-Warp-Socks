FROM debian:bookworm
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Europe/London"

RUN apt-get -qq update \
    && apt-get -qq install curl net-tools \
    && apt-get -qq install --no-install-recommends dante-server iproute2 procps iptables openresolv kmod wireguard \
    && apt-get -qq autoremove --purge && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

CMD ["rws-cli"]
