#!/bin/sh
set -eu

echo "===== SOAL 10: DHCP SERVER AUTOSTART ====="

# Validasi konfigurasi DHCP
echo "[1] Validasi konfigurasi DHCP..."
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# Pastikan interface DHCP server benar
echo "[2] Interface DHCP server:"
cat /etc/default/isc-dhcp-server

# Aktifkan autostart sesuai service manager yang tersedia
if command -v rc-update >/dev/null 2>&1; then
    rc-update add isc-dhcp-server default 2>/dev/null || true
elif command -v systemctl >/dev/null 2>&1; then
    systemctl enable isc-dhcp-server
else
    echo "[INFO] Tidak ada rc-update/systemctl."
    echo "[INFO] Container mungkin menjalankan service melalui startup command."
fi

# Restart dan cek DHCP server
echo "[3] Restart DHCP server..."
service isc-dhcp-server restart

echo "[4] Status DHCP server:"
service isc-dhcp-server status

echo "[5] Konfigurasi pool dan fixed address:"
grep -n -E 'default-lease-time|max-lease-time|pool1|pool2|range|host kugisaki|fixed-address|hardware ethernet' /etc/dhcp/dhcpd.conf

echo "[6] Lease DHCP:"
cat /var/lib/dhcp/dhcpd.leases

echo "===== PEMERIKSAAN TENGEN SELESAI ====="
