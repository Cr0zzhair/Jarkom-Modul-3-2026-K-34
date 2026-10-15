#!/bin/sh
echo "=================================="
echo " DIAGNOSIS API SOAL 16"
echo "=================================="

echo
echo "=== 1. TES GETO DARI GOJO ==="
curl -i --connect-timeout 3 --max-time 5 http://192.228.4.2/
echo

echo
echo "=== 2. TES ENDPOINT API GETO ==="
curl -i --connect-timeout 3 --max-time 5 http://192.228.4.2/api
echo

echo
echo "=== 3. LOG ERROR NGINX GOJO ==="
tail -n 30 /var/log/nginx/error.log

echo
echo "=== 4. KONFIGURASI PROXY GOJO ==="
nginx -T 2>&1 | grep -A 35 -B 5 -E 'upstream api_gateway|location = /api|location \^~ /api/'

echo
echo "=================================="
echo " DIAGNOSIS SELESAI"
echo "=================================="
