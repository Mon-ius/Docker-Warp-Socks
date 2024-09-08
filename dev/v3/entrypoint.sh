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
    "dns": {
        "servers": [
            {
                "tag": "google",
                "address": "tls://8.8.8.8",
                "detour": "WARP"
            },
            {
                "tag": "fallback",
                "address": "8.8.8.8",
                "address_resolver": "google",
                "detour": "WARP"
            },
            {
                "tag": "local-dns",
                "address": "223.5.5.5",
                "detour": "direct"
            },
            {
                "tag": "block-dns",
                "address": "rcode://success"
            }
        ],
        "rules": [
            {
                "outbound": "any",
                "server": "local-dns"
            },
            {
                "query_type": [
                    "A"
                ],
                "rewrite_ttl": 1,
                "server": "fallback"
            }
        ],
        "strategy": "ipv4_only"
    },
    "route": {
        "rules": [
            {
                "protocol": "dns",
                "outbound": "dns-out"
            },
            {
                "port": 53,
                "outbound": "dns-out"
            },
            {
                "type": "logical",
                "mode": "or",
                "rules": [
                    {
                        "port": 853
                    },
                    {
                        "network": "udp",
                        "port": 443
                    },
                    {
                        "protocol": "stun"
                    }
                ],
                "outbound": "block"
            },
            {
                "ip_is_private": true,
                "outbound": "direct"
            }
        ],
        "auto_detect_interface": true,
        "final": "WARP"
    },
    "outbounds": [
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
            "mtu": 1408
        },
        {
            "type": "direct",
            "tag": "direct"
        },
        {
            "type": "dns",
            "tag": "dns-out"
        },
        {
            "type": "block",
            "tag": "block"
        }
    ],
    "inbounds": [
        {
            "type": "mixed",
            "tag": "mixed-in",
            "listen": "::",
            "listen_port": $NET_PORT,
$AUTH_PART
            "sniff": true
        },
        {
            "type": "direct",
            "listen": "::",
            "listen_port": 53,
            "sniff": true
        }
    ]
}
EOF

if [ ! -e "/usr/bin/rws-cli" ]; then
    echo "sing-box -c /etc/sing-box/config.json run" > /usr/bin/rws-cli && chmod +x /usr/bin/rws-cli
fi

exec "$@"