#!/bin/bash
# SOAL 1 [K-34] — jalankan di jichi:  bash /root/soal1.sh
set -u
GNS3="http://10.4.89.247:3080"
GUSER="K-34"; GPASS="K-34@GNS3"
GH="10.4.89.247"
P="192.228"

# Guard: script ini hanya boleh jalan di jichi (push_soal.py menaruhnya
# di semua node — di node lain harus berhenti agar config tidak tertimpa)
H="$(hostname -s)"
if [ "$H" != "jichi" ]; then
  echo "[soal1] node ini ($H) bukan jichi — lewati (IP server diatur via console jichi)"
  exit 0
fi

# ============ [1/3] KONFIGURASI JICHI ============
echo "===== [1/3] Konfigurasi jichi (WAN + 4 gateway + forwarding + SNAT) ====="

cat > /etc/network/interfaces <<'IFACES'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    post-up sysctl -w net.ipv4.ip_forward=1
    post-up iptables -C -t nat POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

auto eth1
iface eth1 inet static
    address 192.228.1.1/24

auto eth2
iface eth2 inet static
    address 192.228.2.1/24

auto eth3
iface eth3 inet static
    address 192.228.3.1/24

auto eth4
iface eth4 inet static
    address 192.228.4.1/24
IFACES

sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1
iptables -C -t nat POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

for i in 1 2 3 4; do ip addr flush dev eth$i; done
ip addr add ${P}.1.1/24 dev eth1; ip link set eth1 up
ip addr add ${P}.2.1/24 dev eth2; ip link set eth2 up
ip addr add ${P}.3.1/24 dev eth3; ip link set eth3 up
ip addr add ${P}.4.1/24 dev eth4; ip link set eth4 up
echo "nameserver 192.168.122.1" > /etc/resolv.conf

echo "--- jichi ---"; ip -br a

# ============ [2/3] AMBIL PORT CONSOLE SEMUA NODE (API GNS3) ============
echo "===== [2/3] Ambil daftar node + port console dari API GNS3 ====="
apt-get update -qq >/dev/null 2>&1 || true
apt-get install -y -qq curl jq >/dev/null 2>&1 || true
TOKEN=""
for i in $(seq 1 10); do
  TOKEN=$(curl -s -m 5 -X POST $GNS3/v3/access/users/authenticate \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"$GUSER\",\"password\":\"$GPASS\"}" | jq -r '.access_token // empty')
  [ -n "$TOKEN" ] && break
  echo "  menunggu jaringan siap... ($i)"; sleep 3
done
[ -z "$TOKEN" ] && { echo "!! gagal login ke API GNS3"; exit 1; }

PIDX=$(curl -s -m 5 $GNS3/v3/projects -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[] | select(.name=="K-34-MODUL-3") | .project_id' | head -1)
[ -z "$PIDX" ] && { echo "!! project tidak ditemukan"; exit 1; }

curl -s -m 5 $GNS3/v3/projects/$PIDX/nodes -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[] | select(.node_type=="docker") | "\(.name) \(.console)"' > /tmp/nodes.txt
echo "  terdaftar $(wc -l < /tmp/nodes.txt) node docker"

# ============ [3/3] SET IP STATIS SERVER (via console) ============
# CATATAN: 8 klien Net2/Net3 (itodori, fushiguro, Zenin, okukatsu, Ino,
# kusakabe, Kusigaki, Miwa) TIDAK di-set statis di sini — mereka wajib
# memperoleh lease dari tengen via DHCP relay (jalankan soal3.sh).
# Jangan pernah tulis /etc/network/interfaces statis di klien DHCP.
# remote <nama-node> <ip> <gateway>  : ketikkan config ke console node
remote() {
  local n=$1 ip=$2 gw=$3
  local port=$(awk -v N="$n" 'tolower($1)==tolower(N){print $2}' /tmp/nodes.txt)
  if [ -z "$port" ]; then echo "  !! $n: port console tidak ditemukan"; return; fi
  {
    sleep 1
    echo "rm -f /root/soal1.sh /root/setup.sh /root/.keep"
    echo "printf '%s\n' '# [K-34] dikelola dari jichi (soal1.sh)' > /root/.bashrc"
    echo "printf '%s\n' 'auto lo' 'iface lo inet loopback' 'auto eth0' 'iface eth0 inet static' '    address $ip/24' '    gateway $gw' > /etc/network/interfaces"
    echo "echo 'nameserver 192.168.122.1' > /etc/resolv.conf"
    echo "ip addr flush dev eth0; ip addr add $ip/24 dev eth0; ip link set eth0 up; ip route replace default via $gw"
    echo "echo; echo '===== $n SELESAI ($ip) ====='; ip -br a | grep eth0; ping -c2 -W2 $gw >/dev/null 2>&1 && echo '[OK] gateway $gw' || echo '[GAGAL] gateway'; ping -c2 -W2 8.8.8.8 >/dev/null 2>&1 && echo '[OK] internet' || echo '[GAGAL] internet'"
    sleep 10
  } | timeout 40 nc $GH $port &
  echo "  -> $n ($ip) dikirim ke console :$port"
}

echo "===== [3/3] Set IP statis server (paralel dari jichi) ====="
# --- Network 1 (DMZ) ---
remote utahime   ${P}.1.2  ${P}.1.1
remote shoko     ${P}.1.3  ${P}.1.1
remote gojo      ${P}.1.4  ${P}.1.1
# --- Network 4 (Data Center) ---
remote tengen    ${P}.4.10 ${P}.4.1
remote geto      ${P}.4.2  ${P}.4.1
remote maki      ${P}.4.11 ${P}.4.1
remote panda     ${P}.4.12 ${P}.4.1
remote nanami    ${P}.4.13 ${P}.4.1
remote todo      ${P}.4.14 ${P}.4.1
remote kirara    ${P}.4.15 ${P}.4.1
remote yaga      ${P}.4.20 ${P}.4.1
remote inumaki   ${P}.4.21 ${P}.4.1
wait

touch /tmp/.soal1-done
echo
echo "===== SELESAI: JICHI ====="
echo "Bukti tiap host: buka console node -> terlihat IP + '[OK] gateway' + '[OK] internet'"
echo "Uji dari jichi : ping ${P}.1.2 ${P}.4.2 dll."
