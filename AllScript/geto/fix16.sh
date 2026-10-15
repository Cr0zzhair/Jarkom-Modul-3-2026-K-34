#!/bin/sh

echo "=================================="
echo " FIX DAN CEK API SOAL 16 - GETO"
echo "=================================="

echo
echo "=== 1. CEK IP BACKEND ==="
ip route get 192.228.4.13
ip route get 192.228.4.14

echo
echo "=== 2. TES NANAMI ==="
curl -i --connect-timeout 3 --max-time 5 http://192.228.4.13/api
echo

echo "=== 3. TES TODO ==="
curl -i --connect-timeout 3 --max-time 5 http://192.228.4.14/api
echo

echo "=== 4. VALIDASI NGINX ==="
if nginx -t; then
    echo
    echo "Konfigurasi valid. Reload Nginx..."
    if command -v systemctl >/dev/null 2>&1; then
        systemctl reload nginx
    else
        nginx -s reload
    fi
else
    echo "Konfigurasi Nginx salah. Tidak dilakukan reload."
    exit 1
fi

echo
echo "=== 5. TES API GETO ==="
curl -i --connect-timeout 3 --max-time 5 http://127.0.0.1/api
echo

echo "=== 6. LOG ERROR TERBARU ==="
tail -n 15 /var/log/nginx/error.log

echo
echo "=== SELESAI ==="
