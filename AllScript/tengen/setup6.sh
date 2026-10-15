#!/bin/sh
# SOAL 6 K-34
# DHCP Static Lease Kugisaki + DHCP Relay
# Jalankan di tengen: sh /root/setup6.sh

set -eu

CONF="/etc/dhcp/dhcpd.conf"
MAC="02:42:2e:cc:bc:00"
IP="192.228.3.99"

echo "===== SOAL 6: DHCP STATIC LEASE ====="

if [ "$(hostname -s)" != "tengen" ]; then
    echo "[ERROR] Jalankan script ini di tengen."
    exit 1
fi

if [ ! -f "$CONF" ]; then
    echo "[ERROR] File DHCP tidak ditemukan: $CONF"
    exit 1
fi

# Backup konfigurasi DHCP
cp "$CONF" "$CONF.backup6"

# Hapus blok reservasi Soal 6 sebelumnya
sed -i '/^# SOAL6_KUGISAKI_START$/,/^# SOAL6_KUGISAKI_END$/d' "$CONF"

# Hapus definisi Kugisaki yang pernah dibuat oleh script sebelumnya
if grep -qiE '^[[:space:]]*host[[:space:]]+kugisaki[[:space:]]*\{' "$CONF"; then
    echo "[ERROR] Definisi host kugisaki lain ditemukan."
    echo "[INFO] Periksa $CONF sebelum melanjutkan."
    cp "$CONF.backup6" "$CONF"
    exit 1
fi

# Tambahkan reservasi menggunakan MAC aktual Kugisaki
cat >> "$CONF" <<ENDCONFIG

# SOAL6_KUGISAKI_START
host kugisaki {
    hardware ethernet $MAC;
    fixed-address $IP;
}
# SOAL6_KUGISAKI_END
ENDCONFIG

echo
echo "===== VALIDASI DHCP ====="

if ! dhcpd -t -cf "$CONF"; then
    cp "$CONF.backup6" "$CONF"
    echo "[ERROR] Validasi gagal. Backup dipulihkan."
    exit 1
fi

echo "[PASS] Konfigurasi DHCP valid."

echo
echo "===== RESTART DHCP SERVER ====="

if ! service isc-dhcp-server restart; then
    echo "[ERROR] DHCP server gagal direstart."
    exit 1
fi

echo "[PASS] DHCP server direstart."
echo
echo "===== RESERVASI KUGISAKI ====="
grep -A4 -B1 'host kugisaki' "$CONF"

echo
echo "===== LANGKAH BERIKUTNYA ====="
echo "MAC Kugisaki : $MAC"
echo "Fixed IP     : $IP"
echo "Gateway      : 192.228.3.1"
echo
echo "DHCP Relay harus aktif di jichi."
echo "Renew DHCP harus dijalankan di Kugisaki."
echo "Script ini belum menjalankan perintah di kedua node tersebut."
