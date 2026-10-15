#!/bin/sh
set -e

echo "=== SOAL 17: GETO ==="

SITE="/etc/nginx/sites-enabled/geto-api"
CONF="/etc/nginx/conf.d/soal17-realip.conf"
BACKUP="/root/geto-api.soal17.bak"

# Backup di luar folder konfigurasi aktif
if [ ! -f "$BACKUP" ]; then
    cp "$SITE" "$BACKUP"
fi

if [ -f "$CONF" ] && [ ! -f /root/soal17-realip.conf.bak ]; then
    cp "$CONF" /root/soal17-realip.conf.bak
fi

# Konfigurasi trusted proxy
cat > "$CONF" <<'NGINX'
set_real_ip_from 192.228.1.4;
real_ip_header X-Real-IP;
real_ip_recursive off;
NGINX

# Pastikan konfigurasi valid sebelum reload
if nginx -t; then
    nginx -s reload
    echo "BERHASIL: Geto berhasil dimuat ulang."
else
    echo "ERROR: Konfigurasi tidak valid."
    echo "Backup tersedia di /root/geto-api.soal17.bak"
    exit 1
fi

echo "=== HEADER AKTIF ==="
nginx -T 2>&1 | grep -nE 'set_real_ip_from|real_ip_header|proxy_pass|X-Real-IP|X-Forwarded-For'
