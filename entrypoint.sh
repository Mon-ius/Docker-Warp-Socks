#!/bin/bash
set -e

sleep 5

IFACE=$(ip route show default | awk '{print $5}')

if [ ! -e "/opt/wgcf-profile.conf" ]; then
    IPv4=$(ifconfig $IFACE | awk '/inet /{print $2}' | cut -d' ' -f2)
    IPv6=$(ifconfig $IFACE | awk '/inet6 /{print $2}' | cut -d' ' -f2)
    TAR="https://api.github.com/repos/ViRb3/wgcf/releases/latest"
    ARCH=$(dpkg --print-architecture)
    URL=$(curl -fsSL ${TAR} | grep 'browser_download_url' | cut -d'"' -f4 | grep linux | grep "${ARCH}")
    curl -fsSL "${URL}" -o ./wgcf && chmod +x ./wgcf && mv ./wgcf /usr/bin
    wgcf register --accept-tos && wgcf generate && mv wgcf-profile.conf /opt
    sed -i "/\[Interface\]/a PostDown = ip -6 rule delete from ${IPv6}  lookup main" /opt/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -6 rule add from ${IPv6} lookup main" /opt/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostDown = ip -4 rule delete from ${IPv4} lookup main" /opt/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -4 rule add from ${IPv4} lookup main" /opt/wgcf-profile.conf
fi

if [ ! -e "/opt/danted.conf" ]; then
	cat > /opt/danted.conf <<-EOF
		logoutput: stderr
		internal: ${IFACE} port = 9091
		external: warp

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

/bin/cp -rf /opt/wgcf-profile.conf /etc/wireguard/warp.conf && /bin/cp -rf /opt/danted.conf /etc/danted.conf

CURRENT_NAMESERVER=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}')

# Backup the current resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.backup

# Configure dnsmasq
echo -e "no-resolv\nall-servers\nserver=1.1.1.1\nserver=$CURRENT_NAMESERVER" | tee /etc/dnsmasq.conf

# Restart dnsmasq
service dnsmasq restart

/bin/cp -rf /opt/wgcf-profile.conf /etc/wireguard/warp.conf && /bin/cp -rf /opt/danted.conf /etc/danted.conf
wg-quick up warp

# Change resolv.conf to use local DNS
echo "nameserver 127.0.0.1" | tee /etc/resolv.conf

exec "$@"
