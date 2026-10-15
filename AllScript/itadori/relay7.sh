#!/bin/sh
# LOG ASLI relay7.sh: perintah yang terlihat membuat /root/renew7.sh,
# bukan konfigurasi DHCP relay. Dipertahankan sesuai log yang diberikan.

cat > /root/renew7.sh <<'EOF'
#!/bin/sh
# SOAL 7 - RENEW DHCP CLIENT

set -u

IFACE="eth0"

echo "===== SOAL 7: RENEW DHCP ====="

ip link set "$IFACE" up

if ! udhcpc -i "$IFACE" -n -q -t 5 -T 3; then
    echo "[ERROR] Gagal mendapatkan lease DHCP."
    exit 1
fi

echo
echo "===== IP ADDRESS ====="
ip -4 addr show dev "$IFACE"

echo
echo "===== ROUTING ====="
ip route

echo
echo "===== DNS DAN DOMAIN ====="
cat /etc/resolv.conf

echo "===== SELESAI ====="
EOF

chmod +x /root/renew7.sh
sh /root/renew7.sh
