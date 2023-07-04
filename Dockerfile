# Stage 1: Build the project
FROM rust:latest as builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Clone the repository and build the project
RUN git clone https://github.com/KaranGauswami/socks-to-http-proxy.git \
    && cd socks-to-http-proxy \
    && cargo build --release

# Stage 2: Create the final container
FROM debian:latest

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Asia/Ho_Chi_Minh"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    net-tools \
    dante-server \
    wireguard-tools \
    iproute2 \
    procps \
    iptables \
    openresolv \
    kmod \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from the build stage
COPY --from=builder /socks-to-http-proxy/target/release/sthp /usr/local/bin/sthp

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

#CMD ["danted"]

