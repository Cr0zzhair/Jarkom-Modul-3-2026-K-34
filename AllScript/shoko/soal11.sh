#!/bin/bash
# SOAL 11 [K-34] — jalankan di shoko:  bash /root/soal11.sh
# DNS Slave BIND9: zona jujutsu.k34.com transfer otomatis dari utahime (192.228.1.2).
# Zona reverse ikut di soal12.sh.
set -u
P="192.228"
DOMAIN="jujutsu.k34.com"

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
    address ${P}.1.3/24
    gateway ${P}.1.1
EOF
ip addr flush dev eth0; ip addr add ${P}.1.3/24 dev eth0; ip link set eth0 up
ip route replace default via ${P}.1.1 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf

apt update || true
apt install -y bind9 bind9utils dnsutils

cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    listen-on { any; };
    listen-on-v6 { none; };
    recursion yes;
    allow-recursion { ${P}.0.0/16; 127.0.0.1; };
    allow-query { any; };
    dnssec-validation no;
};
EOF

cat > /etc/bind/named.conf.local <<EOF
zone "${DOMAIN}" {
    type slave;
    file "/var/lib/bind/db.${DOMAIN}";
    masters { ${P}.1.2; };
};
EOF

mkdir -p /var/lib/bind; chown bind:bind /var/lib/bind
rm -f /var/lib/bind/db.${DOMAIN} /var/lib/bind/db.rev1
named-checkconf || { echo "!! named.conf salah"; exit 1; }
service named restart; sleep 2
update-rc.d named defaults >/dev/null 2>&1 || true

echo "===== SELESAI: SOAL 11 SLAVE (shoko) ====="
ls -l /var/lib/bind/ | grep -E "db\.${DOMAIN}" && echo "[OK] file zona tertransfer" || echo "!! file zona belum ada (cek master/notify)"
dig @${P}.1.3 ${DOMAIN}. NS +short
dig @${P}.1.3 ${DOMAIN}. SOA +short
echo "Lanjut soal 12 di node ini: bash /root/soal12.sh"
