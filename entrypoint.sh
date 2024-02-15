#!/bin/bash
set -e

sleep 5

_NET_DEV=warp
IFACE=$(ip route show default | awk '{print $5}')
NET_DEV="${NET_DEV:-$_NET_DEV}"

if [ ! -e "/opt/wgcf-profile.conf" ]; then
    IPv4=$(ifconfig "$IFACE" | awk '/inet /{print $2}' | cut -d' ' -f2)
    _IPv4=$(ip addr show dev "$IFACE" | awk '/inet /{print $2}' | cut -d' ' -f2)
    IPv6=$(ifconfig "$IFACE" | awk '/inet6 /{print $2}' | cut -d' ' -f2)
    _IPv6=$(ip addr show dev "$IFACE" | awk '/inet6 /{print $2}' | cut -d' ' -f2)

    TAR="https://api.github.com/repos/ViRb3/wgcf/releases/latest"
    ARCH=$(dpkg --print-architecture)
    URL=$(curl -fsSL ${TAR} | grep 'browser_download_url' | cut -d'"' -f4 | grep linux | grep "${ARCH}")
    curl -fsSL "${URL}" -o ./wgcf && chmod +x ./wgcf && mv ./wgcf /usr/bin
    wgcf register --accept-tos && wgcf update && wgcf generate && mv wgcf-profile.conf /opt
    sed -i "/\[Interface\]/a PostDown = ip -6 rule delete from ${IPv6}  lookup main" /opt/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -6 rule add from ${IPv6} lookup main" /opt/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostDown = ip -4 rule delete from ${IPv4} lookup main" /opt/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -4 rule add from ${IPv4} lookup main" /opt/wgcf-profile.conf
fi

if [ ! -e "/opt/danted.conf" ]; then

cat <<EOF | tee /opt/danted.conf
logoutput: stderr
internal: 0.0.0.0 port=9091
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
    useradd "$SOCK_USER" && echo "$SOCK_USER:$SOCK_PWD" | chpasswd
    sed -i 's/socksmethod: none/socksmethod: username/g' /opt/danted.conf
fi


/bin/cp -rf /opt/wgcf-profile.conf /etc/wireguard/"$NET_DEV".conf && /bin/cp -rf /opt/danted.conf /etc/danted.conf
wg-quick up warp

exec "$@"