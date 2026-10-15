#!/bin/sh

echo "===== SOAL 7: RENEW DHCP ====="

ip link set eth0 up

if ! udhcpc -i eth0 -n -q -t 5 -T 3; then
    echo "[ERROR] Gagal mendapatkan lease DHCP."
    exit 1
fi

echo ""
echo "===== IP ADDRESS ====="
ip addr show eth0

echo ""
echo "===== ROUTING ====="
ip route

echo ""
echo "===== DNS DAN DOMAIN ====="
cat /etc/resolv.conf

echo ""
echo "===== SELESAI ====="
