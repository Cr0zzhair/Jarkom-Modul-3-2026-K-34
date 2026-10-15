#!/bin/bash
# SOAL 12 [K-34] — jalankan di utahime SETELAH soal 11:  bash /root/soal12.sh
# Peta domain + jalan keluar internet:
# A jujutsu.k34.com -> gojo, CNAME www, Reverse PTR gojo, Forwarder 192.168.122.1.
set -u
P="192.228"
DOMAIN="jujutsu.k34.com"
SERIAL="2026101201"        # serial naik -> slave ikut transfer otomatis (bukti soal 11 juga)

grep -q 'zone "1.228.192.in-addr.arpa"' /etc/bind/named.conf.local 2>/dev/null || cat >> /etc/bind/named.conf.local <<EOF
zone "1.228.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.rev1";
    allow-transfer { ${P}.1.3; };
    also-notify { ${P}.1.3; };
};
EOF

# Options + forwarder internet (ditulis ulang penuh agar idempoten)
cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    listen-on { any; };
    listen-on-v6 { none; };
    recursion yes;
    allow-recursion { ${P}.0.0/16; 127.0.0.1; };
    allow-query { any; };
    forwarders { 192.168.122.1; };
    forward only;
    dnssec-validation no;
};
EOF

# Zona maju ditulis ulang penuh: isi soal 11 + A @ + CNAME www, serial baru
cat > /etc/bind/db.${DOMAIN} <<EOF
\$TTL 60
@   IN  SOA ns1.${DOMAIN}. root.${DOMAIN}. (
        ${SERIAL}  ; serial tahap 12 (naik -> picu transfer ke slave)
        3600       ; refresh
        600        ; retry
        604800     ; expire
        60 )       ; minimum
@   IN  NS  ns1.${DOMAIN}.
@   IN  NS  ns2.${DOMAIN}.
ns1 IN  A   ${P}.1.2
ns2 IN  A   ${P}.1.3
@   IN  A   ${P}.1.4
www IN  CNAME ${DOMAIN}.
EOF

# Zona reverse: IP gojo kembali ke domain resmi
cat > /etc/bind/db.rev1 <<EOF
\$TTL 60
@   IN  SOA ns1.${DOMAIN}. root.${DOMAIN}. (
        ${SERIAL}
        3600 600 604800 60 )
@   IN  NS  ns1.${DOMAIN}.
@   IN  NS  ns2.${DOMAIN}.
4   IN  PTR ${DOMAIN}.
2   IN  PTR ns1.${DOMAIN}.
3   IN  PTR ns2.${DOMAIN}.
EOF

chown bind:bind /etc/bind/db.${DOMAIN} /etc/bind/db.rev1
named-checkconf || { echo "!! named.conf salah"; exit 1; }
named-checkzone ${DOMAIN} /etc/bind/db.${DOMAIN}
named-checkzone 1.228.192.in-addr.arpa /etc/bind/db.rev1
service named restart; sleep 1

echo "===== SELESAI: SOAL 12 MASTER (utahime) ====="
dig +short @${P}.1.2 ${DOMAIN}.
dig +short @${P}.1.2 www.${DOMAIN}.
dig +short -x ${P}.1.4 @${P}.1.2
dig +short @${P}.1.2 google.com | head -2
echo "Cek di shoko (transfer serial ${SERIAL}): dig @${P}.1.3 ${DOMAIN}. SOA +short"
