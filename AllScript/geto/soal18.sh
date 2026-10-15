#!/bin/sh
set -e

SITE="/etc/nginx/sites-enabled/geto-api"
BACKUP="/root/geto-api.soal18.bak"

echo "=== SOAL 18: GETO API BACKUP ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Jalankan sebagai root."
    exit 1
fi

if [ ! -f "$SITE" ]; then
    echo "ERROR: Konfigurasi $SITE tidak ditemukan."
    exit 1
fi

# Simpan backup konfigurasi awal satu kali.
if [ ! -f "$BACKUP" ]; then
    cp "$SITE" "$BACKUP"
fi

# Ganti hanya blok upstream api_cluster.
awk '
/^[[:space:]]*upstream[[:space:]]+api_cluster[[:space:]]*\{/ {
    print "upstream api_cluster {"
    print "    server 192.228.4.13 weight=3 max_fails=2 fail_timeout=5s;"
    print "    server 192.228.4.14 weight=1 max_fails=2 fail_timeout=5s;"
    print "    server 192.228.4.15 backup;"
    inside=1
    next
}
inside && /^[[:space:]]*}/ {
    print "}"
    inside=0
    next
}
!inside { print }
' "$BACKUP" > "$SITE"

if nginx -t; then
    nginx -s reload
    echo "BERHASIL: Upstream API diperbarui."
else
    echo "ERROR: Konfigurasi tidak valid; pulihkan backup."
    cp "$BACKUP" "$SITE"
    exit 1
fi

echo "=== UPSTREAM AKTIF ==="
nginx -T 2>&1 | grep -E 'upstream api_cluster|192\.228\.4\.(13|14|15)'
