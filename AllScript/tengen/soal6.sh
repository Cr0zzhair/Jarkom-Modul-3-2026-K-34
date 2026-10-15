#!/bin/sh
# SOAL 6 - DHCP STATIC LEASE KUGISAKI
# Jalankan di Tengen sebagai root

set -eu

CONFIG="/etc/dhcp/dhcpd.conf"
MAC="02:42:2e:cc:bc:00"
IP="192.228.3.99"
START="# SOAL6_KUGISAKI_START"
END="# SOAL6_KUGISAKI_END"

echo "===== SOAL 6: STATIC LEASE KUGISAKI ====="

if [ ! -f "$CONFIG" ]; then
    echo "[ERROR] File konfigurasi DHCP tidak ditemukan."
    exit 1
fi

echo "[1] Memeriksa pool dinamis..."
if grep -Eq 'range[[:space:]]+192\.228\.3\.99([[:space:]]|;)' "$CONFIG"; then
    echo "[ERROR] IP 192.228.3.99 masuk pool dinamis."
    echo "Sesuaikan pool terlebih dahulu."
    exit 1
fi

echo "[2] Membuat backup konfigurasi..."
cp "$CONFIG" "$CONFIG.backup-soal6"

echo "[3] Menghapus reservasi Soal 6 sebelumnya..."
TMP="$(mktemp)"
awk -v start="$START" -v end="$END" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; next }
    !skip { print }
' "$CONFIG" > "$TMP"
cp "$TMP" "$CONFIG"
rm -f "$TMP"

echo "[4] Menambahkan static lease..."
cat >> "$CONFIG" <<EOC

$START
host kugisaki {
    hardware ethernet $MAC;
    fixed-address $IP;
}
$END
EOC

echo "[5] Memvalidasi konfigurasi DHCP..."
if dhcpd -t -cf "$CONFIG"; then
    echo "[PASS] Konfigurasi DHCP valid."
else
    echo "[ERROR] Konfigurasi tidak valid. Memulihkan backup."
    cp "$CONFIG.backup-soal6" "$CONFIG"
    exit 1
fi

echo "[6] Me-restart DHCP server..."
if service isc-dhcp-server restart; then
    echo "[PASS] DHCP server berhasil direstart."
else
    echo "[ERROR] DHCP server gagal direstart."
    echo "Backup tersedia di $CONFIG.backup-soal6"
    exit 1
fi

echo "[7] Reservasi yang diterapkan:"
grep -A 3 -B 1 'host kugisaki' "$CONFIG"

echo "===== SELESAI DI TENGEN ====="
echo "MAC Kugisaki : $MAC"
echo "Fixed IP     : $IP"
echo "Backup       : $CONFIG.backup-soal6"
echo "Berikutnya: jalankan script relay di Jichi, lalu renew DHCP di Kugisaki."
