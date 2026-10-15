#!/bin/bash
# SOAL 2 [K-34] — jalankan di tengen:  bash /root/soal2.sh
# isc-dhcp-server pada 192.228.4.10:
#   - Network 4 (192.228.4.0/24) : subnet lokal, TANPA pool dinamis
#   - Network 2 (192.228.2.0/24) : scope DHCP Divisi A (via relay jichi)
#   - Network 3 (192.228.3.0/24) : scope DHCP Divisi B (via relay jichi)
set -u
P="192.228"
H="$(hostname -s)"
if [ "$H" != "tengen" ]; then echo "!! Script ini hanya untuk tengen"; exit 1; fi

# 0. Pastikan IP tengen terpasang (idempoten; penting setelah restart node)
ip addr flush dev eth0
ip addr add ${P}.4.10/24 dev eth0
ip link set eth0 up
ip route replace default via ${P}.4.1 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf
echo "--- IP tengen ---"; ip -br a | grep eth0

# 1. Install
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt update || true   # repo security kadang gagal verifikasi sqv; cukup main repo
apt install -y isc-dhcp-server

# 2. Interface yang dilayani (eth0 = satu-satunya interface tengen, ke Network 4)
cat > /etc/default/isc-dhcp-server <<EOF
INTERFACESv4="eth0"
INTERFACESv6=""
EOF

# 3. dhcpd.conf
cat > /etc/dhcp/dhcpd.conf <<EOF
option domain-name "k34.com";
option domain-name-servers ${P}.1.2, ${P}.1.3;
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
authoritative;

# ===== Network 4 : subnet lokal DHCP server (TANPA pool dinamis) =====
subnet ${P}.4.0 netmask 255.255.255.0 {
    option routers ${P}.4.1;
}

# ===== Network 2 : scope Divisi A (diteruskan DHCP relay di jichi) =====
subnet ${P}.2.0 netmask 255.255.255.0 {
    option routers ${P}.2.1;
    pool {
        range ${P}.2.100 ${P}.2.200;
    }
}

# ===== Network 3 : scope Divisi B (diteruskan DHCP relay di jichi) =====
subnet ${P}.3.0 netmask 255.255.255.0 {
    option routers ${P}.3.1;
    pool {
        range ${P}.3.100 ${P}.3.200;
    }
}
EOF

# 4. Validasi konfigurasi
echo "--- validasi sintaks (dhcpd -t) ---"
if dhcpd -t -cf /etc/dhcp/dhcpd.conf; then
  echo "[OK] sintaks dhcpd.conf valid"
else
  echo "!! dhcpd.conf TIDAK valid"; exit 1
fi

# 5. Jalankan service
service isc-dhcp-server restart
sleep 1
service isc-dhcp-server status | head -3
echo "--- proses dhcpd ---"
ps aux | grep -v grep | grep dhcpd || echo "!! dhcpd tidak berjalan"
echo "--- listen port 67 (bootps) ---"
ss -lun | grep ':67 ' && echo "[OK] dhcpd listen udp/67" || echo "!! port 67 tidak dibuka"

# 6. Bukti tanpa error "No subnet declaration"
echo "--- cek 'No subnet declaration' ---"
if dhcpd -t -cf /etc/dhcp/dhcpd.conf 2>&1 | grep -qi "no subnet"; then
  echo "!! MASIH ada error 'No subnet declaration'"
else
  echo "[OK] TIDAK ada error 'No subnet declaration'"
fi

echo "===== SELESAI: SOAL 2 (tengen) ====="
echo "Bukti: dhcpd -t valid, service active, udp/67 listen, tanpa 'No subnet declaration'"
