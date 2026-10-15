#!/bin/sh
# SOAL 6 - DHCP RELAY JICHI

set -eu

SERVER="192.228.4.10"

echo "===== SOAL 6: DHCP RELAY JICHI ====="

echo "[1] Mengaktifkan IP forwarding..."
sysctl -w net.ipv4.ip_forward=1

echo "[2] Memeriksa relay yang sudah berjalan..."
if pgrep -f 'dhcrelay.*192\.228\.4\.10' >/dev/null 2>&1; then
    echo "[PASS] DHCP relay sudah berjalan."
    ps aux | grep '[d]hcrelay'
    exit 0
fi

echo "[3] Memastikan dhcrelay tersedia..."
if ! command -v dhcrelay >/dev/null 2>&1; then
    echo "[ERROR] dhcrelay tidak ditemukan."
    echo "Install isc-dhcp-relay terlebih dahulu."
    exit 1
fi

echo "[4] Menjalankan DHCP relay..."
dhcrelay -4 -i eth3 -i eth4 "$SERVER" >/tmp/relay6.log 2>&1 &
sleep 2

echo "[5] Memeriksa proses relay..."
if pgrep -f 'dhcrelay.*192\.228\.4\.10' >/dev/null 2>&1; then
    echo "[PASS] DHCP relay berjalan."
    ps aux | grep '[d]hcrelay'
else
    echo "[ERROR] DHCP relay gagal berjalan."
    cat /tmp/relay6.log
    exit 1
fi

echo "===== SELESAI ====="
