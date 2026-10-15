#!/bin/sh
set -eu

echo "===== SOAL 10: DHCP RELAY AUTOSTART ====="

# Pastikan script relay tersedia
if [ ! -f /root/relay7.sh ]; then
    echo "[ERROR] /root/relay7.sh tidak ditemukan."
    exit 1
fi

chmod +x /root/relay7.sh

# Buat startup script yang menjalankan relay saat boot
mkdir -p /etc/local.d

cat > /etc/local.d/dhcp-relay.start <<'EOC'
#!/bin/sh
if ! pidof dhcrelay >/dev/null 2>&1; then
    /root/relay7.sh
fi
EOC

chmod +x /etc/local.d/dhcp-relay.start

# Aktifkan local service jika OpenRC tersedia
if command -v rc-update >/dev/null 2>&1; then
    rc-update add local default
    rc-service local start || true
elif command -v systemctl >/dev/null 2>&1; then
    echo "[INFO] systemd tersedia; konfigurasi startup perlu disesuaikan."
else
    echo "[INFO] Service manager tidak ditemukan."
    echo "[INFO] Startup script sudah dibuat, tetapi autostart belum terverifikasi."
fi

# Jalankan relay sekarang
echo "[1] Jalankan DHCP relay..."
sh /root/relay7.sh

echo "[2] Status DHCP relay:"
ps aux | grep '[d]hcrelay'

echo "[3] IP interface jaringan:"
ip addr show eth2
ip addr show eth3
ip addr show eth4

echo "===== PEMERIKSAAN JICHI SELESAI ====="
