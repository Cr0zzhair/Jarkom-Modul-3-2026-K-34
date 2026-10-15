#!/bin/bash
# SOAL 11 [K-34] — jalankan di utahime:  bash /root/soal11.sh
# DNS Master BIND9 untuk zone jujutsu.k34.com:
# SOA + NS delegasi (ns1/ns2) + allow-transfer ke shoko (192.228.1.3).
# Isi soal 12 (A, CNAME, PTR, forwarder) TIDAK di sini, ada di soal12.sh.
set -u
P="192.228"
DOMAIN="jujutsu.k34.com"   # jujutsu.<xxxx>.com, xxxx=K34
SERIAL="2026101101"        # serial tahap 11; soal12.sh menaikkannya lagi

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
    address ${P}.1.2/24
    gateway ${P}.1.1
EOF
ip addr flush dev eth0; ip addr add ${P}.1.2/24 dev eth0; ip link set eth0 up
ip route replace default via ${P}.1.1 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf

apt update || true
apt install -y bind9 bind9utils dnsutils

# Options tahap 11: otoritatif + recursion internal, TANPA forwarder (forwarder = soal 12)
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
    type master;
    file "/etc/bind/db.${DOMAIN}";
    allow-transfer { ${P}.1.3; };
    also-notify { ${P}.1.3; };
};
EOF

# Zona tahap 11: SOA + NS + glue ns1/ns2 saja (belum ada A @ / CNAME / reverse)
cat > /etc/bind/db.${DOMAIN} <<EOF
\$TTL 60
@   IN  SOA ns1.${DOMAIN}. root.${DOMAIN}. (
        ${SERIAL}  ; serial tahap 11
        3600       ; refresh
        600        ; retry
        604800     ; expire
        60 )       ; minimum
@   IN  NS  ns1.${DOMAIN}.
@   IN  NS  ns2.${DOMAIN}.
ns1 IN  A   ${P}.1.2
ns2 IN  A   ${P}.1.3
EOF

chown bind:bind /etc/bind/db.${DOMAIN}
named-checkconf || { echo "!! named.conf salah"; exit 1; }
named-checkzone ${DOMAIN} /etc/bind/db.${DOMAIN}
service named restart; sleep 1
update-rc.d named defaults >/dev/null 2>&1 || true

echo "===== SELESAI: SOAL 11 MASTER (utahime) ====="
dig +short @${P}.1.2 ${DOMAIN}. NS
dig @${P}.1.2 ${DOMAIN}. SOA +short
echo "Lanjut soal 12 di node ini: bash /root/soal12.sh"
