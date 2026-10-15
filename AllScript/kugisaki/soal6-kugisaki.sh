#!/bin/sh
# K-34 - SOAL 6: DHCP Client Kugisaki

set -u

EXPECTED_IP="192.228.3.99"
IFACE="eth0"

echo "===== SOAL 6: KUGISAKI DHCP CLIENT ====="

echo "[1] Memastikan interface aktif..."
ip link set "$IFACE" up

echo "[2] Meminta alamat IP dari DHCP server..."
ip addr flush dev "$IFACE"
if ! udhcpc -i "$IFACE" -n -q; then
    echo "[ERROR] Gagal mendapatkan lease DHCP."
    echo "Periksa DHCP relay di jichi dan DHCP server di tengen."
    exit 1
fi

echo "[3] Memeriksa alamat IPv4..."
ip -4 addr show dev "$IFACE"

ACTUAL_IP=$(ip -4 -o addr show dev "$IFACE" |
    awk '{split($4,a,"/"); print a[1]}')

echo "[4] Memeriksa hasil..."
if [ "$ACTUAL_IP" = "$EXPECTED_IP" ]; then
    echo "[PASS] Kugisaki mendapat IP $EXPECTED_IP"
else
    echo "[ERROR] IP yang didapat: ${ACTUAL_IP:-TIDAK ADA}"
    echo "[ERROR] IP yang diharapkan: $EXPECTED_IP"
    exit 1
fi

echo "[5] Memeriksa routing..."
ip route

echo "===== SOAL 6 SELESAI ====="
