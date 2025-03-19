#!/bin/sh

set -e

sleep 3

_WARP_SERVER=engage.cloudflareclient.com
_WARP_PORT=2408
_NET_PORT=9091

WARP_SERVER="${WARP_SERVER:-$_WARP_SERVER}"
WARP_PORT="${WARP_PORT:-$_WARP_PORT}"
NET_PORT="${NET_PORT:-$_NET_PORT}"

RESPONSE=$(curl -fsSL bit.ly/warp_socks | sh -s -- "$WARP_LICENSE")
private_key=$(echo "$RESPONSE" | sed -n 's/.*"private_key":"\([^"]*\)".*/\1/p')
ipv4=$(echo "$RESPONSE" | sed -n 's/.*"v4":"\([^"]*\)".*/\1/p')
ipv6=$(echo "$RESPONSE" | sed -n 's/.*"v6":"\([^"]*\)".*/\1/p')
public_key=$(echo "$RESPONSE" | sed -n 's/.*"public_key":"\([^"]*\)".*/\1/p')
client_hex=$(echo "$RESPONSE" | grep -o '"client_id":"[^"]*' | cut -d'"' -f4 | base64 -d | od -t x1 -An | tr -d ' \n')
reserved_dec=$(echo "$client_hex" | awk '{printf "[%d, %d, %d]", "0x"substr($0,1,2), "0x"substr($0,3,2), "0x"substr($0,5,2)}')

if [ -n "$SOCK_USER" ] && [ -n "$SOCK_PWD" ]; then
    AUTH_PART=$(cat <<EOF
            "users": [
                {
                    "username": "$SOCK_USER",
                    "password": "$SOCK_PWD"
                }
            ],
EOF
)
else
    AUTH_PART=""
fi

# Default DNS configuration
DNS_CONFIG=$(cat <<EOF
{
    "servers": [
        {
            "tag": "cloudflare-1",
            "address": "udp://1.1.1.1",
            "detour": "direct-out"
        },
        {
            "tag": "cloudflare-2",
            "address": "udp://1.0.0.1",
            "detour": "direct-out"
        },
        {
            "tag": "quad9",
            "address": "udp://9.9.9.9",
            "detour": "direct-out"
        },
        {
            "tag": "opendns-1",
            "address": "udp://208.67.222.222",
            "detour": "direct-out"
        },
        {
            "tag": "opendns-2",
            "address": "udp://208.67.220.220",
            "detour": "direct-out"
        },
        {
            "tag": "google-1",
            "address": "udp://8.8.8.8",
            "detour": "direct-out"
        },
        {
            "tag": "google-2",
            "address": "udp://8.8.4.4",
            "detour": "direct-out"
        }
    ],
    "final": "cloudflare-1",
    "strategy": "prefer_ipv4",
    "reverse_mapping": true,
    "disable_cache": false,
    "disable_expire": false
}
EOF
)

# Custom DNS servers if provided
if [ -n "$CUSTOM_DNS_SERVERS" ]; then
    DNS_CONFIG=$(echo "$DNS_CONFIG" | jq --argjson custom_dns_servers "$CUSTOM_DNS_SERVERS" '.servers += $custom_dns_servers')
fi

# Final DNS server if provided
if [ -n "$CUSTOM_DNS_FINAL" ]; then
    DNS_CONFIG=$(echo "$DNS_CONFIG" | jq --arg custom_dns_final "$CUSTOM_DNS_FINAL" '.final = $custom_dns_final')
fi

PROXY_PART=$(cat <<EOF
    "endpoints": [
        {
            "tag": "WARP",
            "type": "wireguard",
            "address": [
                "${ipv4}/32",
                "${ipv6}/128"
            ],
            "private_key": "$private_key",
            "peers": [
                {
                    "address": "$WARP_SERVER",
                    "port": $WARP_PORT,
                    "public_key": "$public_key",
                    "allowed_ips": [
                        "0.0.0.0/0"
                    ],
                    "persistent_keepalive_interval": 15,
                    "reserved": $reserved_dec
                }
            ],
            "mtu": 1408,
            "udp_fragment": true,
            "tcp_fast_open": true,
            "tcp_multi_path": true
        }
    ]
EOF
)

cat <<EOF | tee /etc/sing-box/config.json
{
    "dns": $DNS_CONFIG,
    "route": {
        "rules": [
            {
                "inbound": "mixed-in",
                "action": "sniff"
            },
            {
                "protocol": "dns",
                "action": "hijack-dns",
            },
            {
                "ip_is_private": true,
                "outbound": "direct-out"
            },
            {
                "ip_cidr": [
                    "10.0.0.0/8",
                    "172.16.0.0/12",
                    "192.168.0.0/16",
                    "127.0.0.0/8",
                    "169.254.0.0/16",
                    "224.0.0.0/4",
                    "240.0.0.0/4"
                ],
                "outbound": "direct-out"
            }
        ],
        "auto_detect_interface": true,
        "final": "WARP",
    },
    "inbounds": [
        {
            "type": "mixed",
            "tag": "mixed-in",
            "listen": "::",
$AUTH_PART
            "listen_port": $NET_PORT,
        }
    ],
$PROXY_PART,
    "outbounds": [
        {
            "tag": "direct-out",
            "type": "direct",
            "udp_fragment": true
        },
    ],
}
EOF

if [ ! -e "/usr/bin/rws-cli" ]; then
    echo "sing-box -c /etc/sing-box/config.json run" > /usr/bin/rws-cli && chmod +x /usr/bin/rws-cli
fi

exec "$@"
