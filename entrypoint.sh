#!/bin/sh

set -e

sleep 3

_WARP_SERVER=engage.cloudflareclient.com
_WARP_PORT=2408
_NET_PORT=9091

WARP_SERVER="${WARP_SERVER:-$_WARP_SERVER}"
WARP_PORT="${WARP_PORT:-$_WARP_PORT}"
NET_PORT="${NET_PORT:-$_NET_PORT}"

RESPONSE=$(curl -fsSL bit.ly/warp_socks | sh -s -- $WARP_LICENSE)
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

WARP_PART=$(cat <<EOF
        {
            "tag": "WARP",
            "type": "wireguard",
            "server": "$WARP_SERVER",
            "server_port": $WARP_PORT,
            "local_address": [
                "${ipv4}/32",
                "${ipv6}/128"
            ],
            "private_key": "$private_key",
            "peer_public_key": "$public_key",
            "reserved": $reserved_dec,
            "mtu": 1408,
            "udp_fragment": true
        }
EOF
)

cat <<EOF | tee /etc/sing-box/config.json
{
    "log": {
        "disabled": false,
        "level": "debug",
        "timestamp": true
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "cache.db",
            "cache_id": "v1",
            "store_fakeip": true
        }
    },
    "outbounds": [
        {
            "tag": "direct-out",
            "type": "direct",
            "udp_fragment": true
        },
        {
            "type": "dns",
            "tag": "dns-out"
        },
        {
            "type": "block",
            "tag": "block"
        },
$WARP_PART
    ],
    "dns": {
        "servers": [
            {
                "tag": "ND-h3",
                "address": "h3://dns.nextdns.io/x",
                "address_resolver": "dns-direct",
                "detour": "direct-out"
            },
            {
                "tag": "dns-direct",
                "address": "udp://223.5.5.5",
                "detour": "direct-out"
            }
        ],
        "strategy": "ipv4_only",
        "final": "ND-h3",
        "reverse_mapping": true,
        "disable_cache": false,
        "disable_expire": false
    },
    "route": {
        "rules": [
            {
                "protocol": "dns",
                "outbound": "dns-out"
            },
            {
                "ip_is_private": true,
                "outbound": "direct-out"
            },
            {
                "ip_cidr": [
                    "0.0.0.0/8",
                    "10.0.0.0/8",
                    "127.0.0.0/8",
                    "169.254.0.0/16",
                    "172.16.0.0/12",
                    "192.168.0.0/16",
                    "224.0.0.0/4",
                    "240.0.0.0/4",
                    "52.80.0.0/16"
                ],
                "outbound": "direct-out"
            }
        ],
        "auto_detect_interface": true,
        "final": "WARP"
    },
    "inbounds": [
        {
            "type": "mixed",
            "tag": "mixed-in",
            "listen": "::",
            "listen_port": $NET_PORT,
$AUTH_PART
            "sniff": true
        }
    ]
}
EOF

if [ ! -e "/usr/bin/rws-cli" ]; then
    echo "sing-box -c /etc/sing-box/config.json run" > /usr/bin/rws-cli && chmod +x /usr/bin/rws-cli
fi

exec "$@"