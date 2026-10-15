#!/bin/sh
set -eu

SITE="/etc/nginx/conf.d/jujutsu.conf"
ZONE="/etc/nginx/conf.d/soal19-zones.conf"
BACKUP="/root/jujutsu.soal19.bak"

echo "=== SOAL 19: CACHE + RATE LIMITING ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Jalankan sebagai root."
    exit 1
fi

if [ ! -f "$SITE" ]; then
    echo "ERROR: Konfigurasi Gojo tidak ditemukan."
    exit 1
fi

if ! grep -q 'proxy_pass http://frontend_pool' "$SITE" ||
   ! grep -q 'proxy_pass http://api_gateway' "$SITE"; then
    echo "ERROR: Routing frontend/API tidak ditemukan."
    exit 1
fi

# Backup konfigurasi asli di luar folder konfigurasi Nginx.
if [ ! -f "$BACKUP" ]; then
    cp "$SITE" "$BACKUP"
fi

# Zone harus didefinisikan dalam konteks http.
if [ ! -f "$ZONE" ]; then
    cat > "$ZONE" <<'NGINX'
proxy_cache_path /var/cache/nginx/frontend
    levels=1:2
    keys_zone=frontend_cache:10m
    max_size=100m
    inactive=30m
    use_temp_path=off;

limit_req_zone $binary_remote_addr
    zone=api_limit:10m
    rate=10r/s;
NGINX
fi

mkdir -p /var/cache/nginx/frontend

# Selalu mulai dari backup asli agar directive tidak berlipat.
awk '
/proxy_pass http:\/\/frontend_pool/ && !cache_added {
    print "        proxy_cache frontend_cache;"
    print "        proxy_cache_valid 200 10m;"
    print "        proxy_cache_methods GET HEAD;"
    print "        add_header X-Cache-Status $upstream_cache_status always;"
    cache_added=1
}
/proxy_pass http:\/\/api_gateway/ {
    print "        limit_req zone=api_limit burst=10 nodelay;"
    print "        limit_req_status 429;"
}
{ print }
END {
    if (!cache_added) exit 2
}
' "$BACKUP" > "$SITE.new"

mv "$SITE.new" "$SITE"

if nginx -t; then
    if nginx -s reload; then
        echo "BERHASIL: Nginx Gojo dimuat ulang."
    else
        echo "ERROR: Reload gagal; memulihkan konfigurasi."
        cp "$BACKUP" "$SITE"
        exit 1
    fi
else
    echo "ERROR: Validasi gagal; memulihkan konfigurasi."
    cp "$BACKUP" "$SITE"
    nginx -t || true
    exit 1
fi

echo "=== PENGATURAN AKTIF ==="
nginx -T 2>&1 | grep -nE \
'proxy_cache_path|limit_req_zone|proxy_cache frontend_cache|X-Cache-Status|limit_req zone=api_limit|limit_req_status'
echo "=== SELESAI ==="
