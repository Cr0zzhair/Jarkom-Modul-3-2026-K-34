#!/bin/bash
# SOAL 12 [K-34] — jalankan di shoko SETELAH soal 11:  bash /root/soal12.sh
# Slave ikut menarik zona reverse (dibuat di utahime oleh soal12.sh).
set -u
P="192.228"
DOMAIN="jujutsu.k34.com"

cat > /etc/bind/named.conf.local <<EOF
zone "${DOMAIN}" {
    type slave;
    file "/var/lib/bind/db.${DOMAIN}";
    masters { ${P}.1.2; };
};
zone "1.228.192.in-addr.arpa" {
    type slave;
    file "/var/lib/bind/db.rev1";
    masters { ${P}.1.2; };
};
EOF

mkdir -p /var/lib/bind; chown bind:bind /var/lib/bind
named-checkconf || { echo "!! named.conf salah"; exit 1; }
service named restart; sleep 3

echo "===== SELESAI: SOAL 12 SLAVE (shoko) ====="
ls -l /var/lib/bind/ | grep -E "db\.${DOMAIN}|db\.rev1" && echo "[OK] kedua file zona ada" || echo "!! transfer belum lengkap"
dig +short @${P}.1.3 ${DOMAIN}.
dig +short @${P}.1.3 www.${DOMAIN}.
dig @${P}.1.3 ${DOMAIN}. SOA +short
