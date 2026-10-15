#!/bin/sh
# SOAL 7 - VERIFY DHCP CONFIGURATION
# Jalankan di Tengen sebagai root

set -u

CONFIG="/etc/dhcp/dhcpd.conf"
LEASES="/var/lib/dhcp/dhcpd.leases"
FAIL=0

check() {
    if "$@"; then
        echo "[PASS] $*"
    else
        echo "[FAIL] $*"
        FAIL=1
    fi
}

echo "===== VERIFY SOAL 7 ====="

echo
echo "[1] Validasi konfigurasi DHCP..."
if dhcpd -t -cf "$CONFIG"; then
    echo "[PASS] Konfigurasi DHCP valid."
else
    echo "[FAIL] Konfigurasi DHCP tidak valid."
    FAIL=1
fi

echo
echo "[2] DNS dan domain-search..."
grep -E 'option domain-name |option domain-name-servers|option domain-search' "$CONFIG"

echo
echo "[3] Gateway dan broadcast..."
grep -E 'option routers|option broadcast-address' "$CONFIG"

echo
echo "[4] Pool dinamis..."
grep -E 'range ' "$CONFIG"

echo
echo "[5] Reservasi Kugisaki..."
grep -A 3 'host kugisaki' "$CONFIG"

echo
echo "[6] Memeriksa file lease..."
if [ -f "$LEASES" ]; then
    echo "[INFO] File lease ditemukan: $LEASES"
    cat "$LEASES"
else
    echo "[FAIL] File lease tidak ditemukan."
    FAIL=1
fi

echo
echo "[7] Status DHCP server..."
if service isc-dhcp-server status; then
    echo "[INFO] Periksa status server di atas."
else
    FAIL=1
fi

echo
if [ "$FAIL" -eq 0 ]; then
    echo "[PASS] Pemeriksaan dasar selesai."
else
    echo "[FAIL] Ada pemeriksaan yang perlu diperbaiki."
    exit 1
fi
