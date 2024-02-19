FROM monius/docker-warp-socks:meta
ENV LOG=0

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

CMD ["rws-cli"]
