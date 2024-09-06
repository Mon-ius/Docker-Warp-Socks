#!/bin/bash
set -e

sleep 3

_NET_DEV=warp
_NET_PORT=9091

NET_DEV="${NET_DEV:-$_NET_DEV}"
NET_PORT="${NET_PORT:-$_NET_PORT}"

_WG_CONF="/etc/wireguard"
_IFACE=$(ip route show default | awk '{print $5}')

if [ ! -e "/opt/wgcf-profile.conf" ]; then
    _IPv4=$(ip addr show dev "$_IFACE" | awk '/inet /{print $2; exit}' | cut -d' ' -f2)
    _IPv6=$(ip addr show dev "$_IFACE" | awk '/inet6 /{print $2; exit}' | cut -d' ' -f2)

    TAR="https://api.github.com/repos/ViRb3/wgcf/releases/latest"
    case $(arch) in
        x86_64) _ARCH="amd64" ;;
        aarch64) _ARCH="arm64" ;;
        s390x) _ARCH="s390x" ;;
        armv7l) _ARCH="armv7" ;;
        *) echo "Unsupported architecture"; exit 1 ;;
    esac
    URL=$(curl -fsSL ${TAR} | grep 'browser_download_url' | cut -d'"' -f4 | grep linux | grep "${_ARCH}")
    curl -fsSL "${URL}" -o ./wgcf && chmod +x ./wgcf && mv ./wgcf /usr/bin
    wgcf register --accept-tos && wgcf update && wgcf generate && mv wgcf-profile.conf /opt
    sed -i "/\[Interface\]/a PostDown = ip -6 rule delete from ${_IPv6}  lookup main" /opt/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -6 rule add from ${_IPv6} lookup main" /opt/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostDown = ip -4 rule delete from ${_IPv4} lookup main" /opt/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -4 rule add from ${_IPv4} lookup main" /opt/wgcf-profile.conf
fi

if [ ! -e "/opt/danted.conf" ]; then

cat <<EOF | tee /opt/danted.conf
logoutput: stderr
internal: 0.0.0.0 port=$NET_PORT
external: $NET_DEV

user.unprivileged: nobody

socksmethod: none
clientmethod: none

client pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
log: error
}

socks pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
}
EOF

fi

if [ -n "$SOCK_USER" ] && [ -n "$SOCK_PWD" ]; then
    adduser --disabled-password --gecos "" "$SOCK_USER" && echo "$SOCK_USER:$SOCK_PWD" | chpasswd
    sed -i 's/socksmethod: none/socksmethod: username/g' /opt/danted.conf
fi

if [ -f /usr/sbin/sockd ]; then
    SOCKS_BIN="/usr/sbin/sockd"
    SOCKS_CONF=/etc/sockd.conf
elif [ -f /usr/sbin/danted ]; then
    SOCKS_BIN="/usr/sbin/danted"
    SOCKS_CONF=/etc/danted.conf
fi

mkdir -p $_WG_CONF && /bin/cp -rf /opt/wgcf-profile.conf "$_WG_CONF/$NET_DEV.conf" && /bin/cp -rf /opt/danted.conf "$SOCKS_CONF"

wg-quick up "$NET_DEV"

if ! curl -fsSL https://www.cloudflare.com/cdn-cgi/trace  | grep -q "warp=on"; then
    sleep 1
    wg-quick down "$NET_DEV" >> /root/wg-error 2>&1
    wg-quick up "$NET_DEV" >> /root/wg-log 2>&1
fi

if [ ! -e "/usr/bin/rws-cli" ]; then
    ln -s "$SOCKS_BIN" /usr/bin/rws-cli && chmod +x /usr/bin/rws-cli
fi

exec "$@"