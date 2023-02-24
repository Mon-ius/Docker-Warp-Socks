#!/bin/bash
set -e

IFACE=$(ip route show | grep default | awk '{print $5}')
IPv4=$(ip -4 address show dev "$IFACE" | awk '/inet/{print $2}' | cut -d/ -f1)
IPv6=$(ip -6 address show dev "$IFACE" | awk '/inet/{print $2}' | cut -d/ -f1)

if [ ! -e "/opt/wgcf-profile.conf" ]; then
	curl -fsSL git.io/wgcf.sh | bash
	wgcf register --accept-tos && wgcf generate && mv wgcf-profile.conf /opt
	sed -i "/\[Interface\]/a PostDown = ip -6 rule delete from ${IPv6}  lookup main" /opt/wgcf-profile.conf
	sed -i "/\[Interface\]/a PostUp = ip -6 rule add from ${IPv6} lookup main" /opt/wgcf-profile.conf
	sed -i "/\[Interface\]/a PostDown = ip -4 rule delete from ${IPv4} lookup main" /opt/wgcf-profile.conf
	sed -i "/\[Interface\]/a PostUp = ip -4 rule add from ${IPv4} lookup main" /opt/wgcf-profile.conf
fi

if [ ! -e "/etc/wireguard/warp.conf" ]; then
    cp /opt/wgcf-profile.conf /etc/wireguard/warp.conf
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

wg-quick up warp && /usr/sbin/danted -f /opt/danted.conf