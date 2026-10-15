#!/bin/sh

echo "=================================="
echo " FIX DAN DIAGNOSIS API - TODO"
echo "=================================="

echo
echo "=== 1. IDENTITAS DAN IP ==="
hostname
ip -4 addr

echo
echo "=== 2. INSTALASI NGINX DAN PHP ==="
apk add --no-cache nginx php84 php84-fpm curl

echo
echo "=== 3. CEK DIREKTORI WEB ==="
ls -la /var/www/ 2>/dev/null
ls -la /var/www/html/ 2>/dev/null

echo
echo "=== 4. CEK KONFIGURASI NGINX ==="
ls -la /etc/nginx/http.d/ 2>/dev/null
nginx -t 2>&1

echo
echo "=== 5. CEK SCRIPT SOAL 14 ==="
if [ -f /root/soal14.sh ]; then
    cat /root/soal14.sh
elif [ -f soal14.sh ]; then
    cat soal14.sh
else
    echo "Script soal14.sh tidak ditemukan."
fi

echo
echo "=== 6. CARI FILE APLIKASI API ==="
find / -name api.php -o -name index.php 2>/dev/null | head -n 30

echo
echo "=== 7. CEK PORT DAN PROSES ==="
ss -lntp 2>/dev/null
ps aux | grep -E '[n]ginx|[p]hp-fpm'

echo
echo "=== 8. CEK LOG NGINX ==="
tail -n 15 /var/log/nginx/error.log 2>/dev/null

echo
echo "=================================="
echo " DIAGNOSIS TODO SELESAI"
echo "=================================="
echo "Jika aplikasi belum ada, script ini tidak membuat aplikasi palsu."
echo "Kirim seluruh output untuk menentukan konfigurasi yang benar."
