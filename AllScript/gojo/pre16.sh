#!/bin/sh
# Diagnosis Soal 16 - jalankan di Gojo

echo "===================================="
echo " DIAGNOSIS BACKEND SOAL 16"
echo "===================================="

echo
echo "=== IP Gojo ==="
hostname
ip -4 addr

echo
echo "=== Routing Gojo ==="
ip route

echo
echo "=== Tes Maki: 192.228.4.11:80 ==="
curl -sS --connect-timeout 3 --max-time 5 -o /dev/null -w 'HTTP=%{http_code} IP=%{remote_ip}\n' http://192.228.4.11/ || echo "Maki tidak dapat diakses"

echo
echo "=== Tes Panda: 192.228.4.12:80 ==="
curl -sS --connect-timeout 3 --max-time 5 -o /dev/null -w 'HTTP=%{http_code} IP=%{remote_ip}\n' http://192.228.4.12/ || echo "Panda tidak dapat diakses"

echo
echo "=== Tes Geto: 192.228.4.2:80 ==="
curl -sS --connect-timeout 3 --max-time 5 -o /dev/null -w 'HTTP=%{http_code} IP=%{remote_ip}\n' http://192.228.4.2/ || echo "Geto tidak dapat diakses"

echo
echo "=== Log error Nginx Gojo ==="
tail -n 30 /var/log/nginx/error.log

echo
echo "=== Selesai ==="
