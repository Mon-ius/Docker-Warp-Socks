#!/bin/sh

set -e

sleep 3

_WARP_SERVER=engage.cloudflareclient.com
_WARP_PORT=2408
_NET_PORT=9091

WARP_SERVER="${WARP_SERVER:-$_WARP_SERVER}"
WARP_PORT="${WARP_PORT:-$_WARP_PORT}"
NET_PORT="${NET_PORT:-$_NET_PORT}"

RESPONSE=$(curl -fsSL bit.ly/create-cloudflare-warp | sh -s)
CF_CLIENT_ID=$(echo "$RESPONSE" | grep -o '"client":"[^"]*' | cut -d'"' -f4 | head -n 1)
CF_ADDR_V4=$(echo "$RESPONSE" | grep -o '"v4":"[^"]*' | cut -d'"' -f4 | tail -n 1)
CF_ADDR_V6=$(echo "$RESPONSE" | grep -o '"v6":"[^"]*' | cut -d'"' -f4 | tail -n 1)

CF_PUBLIC_KEY=$(echo "$RESPONSE" | grep -o '"key":"[^"]*' | cut -d'"' -f4 | head -n 1)
CF_PRIVATE_KEY=$(echo "$RESPONSE" | grep -o '"secret":"[^"]*' | cut -d'"' -f4 | head -n 1)

if [ -z "$CF_CLIENT_ID" ] || [ -z "$CF_PUBLIC_KEY" ] || [ -z "$CF_PRIVATE_KEY" ]; then
    echo "Error: failed to parse WARP credentials" >&2
    exit 1
fi

reserved=$(echo "$CF_CLIENT_ID" | base64 -d | od -An -t u1 | awk '{print "["$1", "$2", "$3"]"}' | head -n 1)

if [ -n "$SOCK_USER" ] && [ -n "$SOCK_PWD" ]; then
AUTH_PART='
            "users": [
                {
                    "username": "'"$SOCK_USER"'",
                    "password": "'"$SOCK_PWD"'"
                }
            ],
'
else
    AUTH_PART=""
fi

DNS_PART='
        "servers": [
            {
                "type": "https",
                "tag": "dns-remote",
                "server": "1.1.1.1",
                "server_port": 443,
                "path": "/dns-query",
                "detour": "WARP",
                "domain_resolver": "dns-local"
            },
            {
                "type": "local",
                "tag": "dns-local"
            }
        ],
        "rules": [
            {
                "ip_is_private": true,
                "server": "dns-local"
            }
        ],
        "final": "dns-remote",
        "strategy": "prefer_ipv4"
'

ROUTE_PART='
        "rules": [
            {
                "action": "sniff"
            },
            {
                "protocol": "dns",
                "action": "hijack-dns"
            },
            {
                "ip_is_private": true,
                "outbound": "direct"
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
                    "52.80.0.0/16",
                    "112.95.0.0/16"
                ],
                "outbound": "direct"
            }
        ],
        "final": "WARP",
        "auto_detect_interface": true,
        "default_domain_resolver": {
            "server": "dns-local"
        }
'

PROXY_PART='
    "endpoints": [
        {
            "type": "wireguard",
            "tag": "WARP",
            "mtu": 1408,
            "address": [
                "'"${CF_ADDR_V4}"'/32",
                "'"${CF_ADDR_V6}"'/128"
            ],
            "private_key": "'"$CF_PRIVATE_KEY"'",
            "peers": [
                {
                    "address": "'"$WARP_SERVER"'",
                    "port": '"$WARP_PORT"',
                    "public_key": "'"$CF_PUBLIC_KEY"'",
                    "allowed_ips": [
                        "0.0.0.0/0",
                        "::/0"
                    ],
                    "persistent_keepalive_interval": 25,
                    "reserved": '"$reserved"'
                }
            ],
            "domain_resolver": "dns-local"
        }
    ],
'

cat <<EOF | tee /etc/sing-box/config.json
{
    "log": {
        "level": "info",
        "timestamp": true
    },
    "dns": {
$DNS_PART
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "/etc/sing-box/cache.db"
        }
    },
    "inbounds": [
        {
            "type": "mixed",
            "tag": "mixed-in",
            "listen": "::",
$AUTH_PART
            "listen_port": $NET_PORT
        }
    ],
    "outbounds": [
        {
            "tag": "direct",
            "type": "direct"
        }
    ],
$PROXY_PART
    "route": {
$ROUTE_PART
    }
}
EOF

if [ ! -e "/usr/bin/rws-cli-v6" ]; then
    printf '#!/bin/sh\nexec sing-box -c /etc/sing-box/config.json run\n' > /usr/bin/rws-cli-v6 && chmod +x /usr/bin/rws-cli-v6
fi

exec "$@"
