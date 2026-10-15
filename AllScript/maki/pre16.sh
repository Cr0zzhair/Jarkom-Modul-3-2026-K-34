#!/bin/sh
echo "===== PRE16B: DIAGNOSIS NGINX ====="

echo
echo "=== PROSES NGINX ==="
ps aux | grep '[n]ginx' || true

echo
echo "=== PROSES PORT 80 ==="
if command -v ss >/dev/null 2>&1; then
    ss -lntp 2>&1 | grep ':80 ' || true
fi

echo
echo "=== KONFIGURASI AKTIF ==="
nginx -T 2>&1 | tail -n 100

echo
echo "=== ERROR LOG ==="
tail -n 50 /var/log/nginx/error.log 2>&1

echo
echo "=== ACCESS LOG ==="
tail -n 20 /var/log/nginx/access.log 2>&1

echo
echo "===== SELESAI ====="
