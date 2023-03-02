FROM monius/docker-warp-socks:meta
ENV LOG=0

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

EXPOSE 9091
CMD ["danted"]
