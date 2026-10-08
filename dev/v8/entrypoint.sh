#!/bin/sh

set -e
umask 077

WARP_API="${WARP_API:-https://api.cloudflareclient.com/v0a2025/reg}"
WARP_SERVER="${WARP_SERVER:-engage.cloudflareclient.com}"
WARP_PORT="${WARP_PORT:-2408}"
NET_PORT="${NET_PORT:-9091}"

TOS="$(date -u +%Y-%m-%dT%H:%M:%S).000Z"

SECRET_KEY=$(openssl genpkey -algorithm X25519)
CF_PRIVATE_KEY=$(printf '%s\n' "$SECRET_KEY" | openssl pkey -outform DER | tail -c 32 | base64)
CF_LOCAL_KEY=$(printf '%s\n' "$SECRET_KEY" | openssl pkey -pubout -outform DER | tail -c 32 | base64)

WARP_PAYLOAD=$(jq -n --arg tos "$TOS" --arg key "$CF_LOCAL_KEY" --arg referrer "${_REF:-}" \
    '{tos: $tos, key: $key, referrer: $referrer}')

RESPONSE=$(curl -fsSL -X POST "$WARP_API" \
    -H "Content-Type: application/json" \
    -d "$WARP_PAYLOAD")

CF_CLIENT_ID=$(printf '%s\n' "$RESPONSE" | jq -r '.config.client_id // empty')
CF_PUBLIC_KEY=$(printf '%s\n' "$RESPONSE" | jq -r '.config.peers[0].public_key // empty')
CF_ADDR_V4=$(printf '%s\n' "$RESPONSE" | jq -r '.config.interface.addresses.v4 // empty')
CF_ADDR_V6=$(printf '%s\n' "$RESPONSE" | jq -r '.config.interface.addresses.v6 // empty')

if [ -z "$CF_CLIENT_ID" ] || [ -z "$CF_PUBLIC_KEY" ] || [ -z "$CF_PRIVATE_KEY" ] || [ -z "$CF_ADDR_V4" ] || [ -z "$CF_ADDR_V6" ]; then
    echo "Error: failed to parse WARP credentials" >&2
    exit 1
fi

reserved=$(printf '%s' "$CF_CLIENT_ID" | base64 -d | od -An -v -t u1 | \
    jq -s 'if length == 3 then . else error("WARP client_id must contain exactly three bytes") end')

# Build JSON with jq so credentials and environment overrides are escaped correctly.
mkdir -p /etc/sing-box
jq -n \
    --arg log_level "${LOG_LEVEL:-info}" \
    --arg username "${SOCK_USER:-}" \
    --arg password "${SOCK_PWD:-}" \
    --argjson net_port "$NET_PORT" \
    --arg warp_server "$WARP_SERVER" \
    --argjson warp_port "$WARP_PORT" \
    --arg private_key "$CF_PRIVATE_KEY" \
    --arg public_key "$CF_PUBLIC_KEY" \
    --arg address_v4 "${CF_ADDR_V4}/32" \
    --arg address_v6 "${CF_ADDR_V6}/128" \
    --argjson reserved "$reserved" '
{
    "log": {
        "level": $log_level,
        "timestamp": true
    },
    "dns": {
        "servers": [
            {
                "type": "https",
                "tag": "dns-remote",
                "server": "1.1.1.1",
                "server_port": 443,
                "path": "/dns-query",
                "detour": "WARP"
            },
            {
                "type": "local",
                "tag": "dns-local"
            }
        ],
        "rules": [
            {
                "action": "evaluate",
                "server": "dns-local"
            },
            {
                "match_response": true,
                "ip_is_private": true,
                "action": "respond"
            }
        ],
        "final": "dns-remote",
        "strategy": "prefer_ipv4"
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "/etc/sing-box/cache.db"
        }
    },
    "inbounds": [
        ({
            "type": "mixed",
            "tag": "mixed-in",
            "listen": "::",
            "listen_port": $net_port
        } + if $username != "" and $password != "" then
            {"users": [{"username": $username, "password": $password}]}
        else {} end)
    ],
    "outbounds": [
        {
            "tag": "direct",
            "type": "direct"
        }
    ],
    "endpoints": [
        {
            "type": "wireguard",
            "tag": "WARP",
            "mtu": 1408,
            "address": [$address_v4, $address_v6],
            "private_key": $private_key,
            "peers": [
                {
                    "address": $warp_server,
                    "port": $warp_port,
                    "public_key": $public_key,
                    "allowed_ips": ["0.0.0.0/0", "::/0"],
                    "persistent_keepalive_interval": 25,
                    "reserved": $reserved
                }
            ],
            "domain_resolver": "dns-local"
        }
    ],
    "route": {
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
                "action": "route",
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
                "action": "route",
                "outbound": "direct"
            }
        ],
        "final": "WARP",
        "auto_detect_interface": true,
        "default_domain_resolver": {
            "server": "dns-local"
        }
    }
}' > /etc/sing-box/config.json

sing-box check -c /etc/sing-box/config.json

if [ ! -e /usr/bin/rws-cli-v8 ]; then
    printf '#!/bin/sh\nexec sing-box -c /etc/sing-box/config.json run\n' > /usr/bin/rws-cli-v8
    chmod +x /usr/bin/rws-cli-v8
fi

exec "$@"
