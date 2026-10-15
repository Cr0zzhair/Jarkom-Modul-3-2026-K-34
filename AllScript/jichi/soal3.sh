#!/bin/bash
# SOAL 3 [K-34] — jalankan di jichi:  bash /root/soal3.sh
# DHCP Relay di jichi -> tengen (192.228.4.10).
# INTERFACES wajib menyertakan eth4 (jalur balik paket OFFER/ACK dari server);
# tanpa eth4, relay hanya meneruskan DISCOVER tapi jawaban server tidak
# pernah sampai ke klien (terbukti saat pengujian).
# Lalu picu udhcpc di 8 klien dan buktikan lease diperoleh via relay.
set -u
P="192.228"
GH="10.4.89.247"   # host GNS3 (port console node)

# ---------- 1. Konfigurasi DHCP Relay ----------
apt update || true
apt install -y isc-dhcp-relay
cat > /etc/default/isc-dhcp-relay <<EOF
SERVERS="${P}.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF
service isc-dhcp-relay restart
sleep 1
ps aux | grep -v grep | grep dhcrelay >/dev/null \
  && echo "[OK] dhcrelay aktif -> ${P}.4.10 (eth2 eth3 eth4)" \
  || { echo "!! dhcrelay gagal jalan"; exit 1; }

# ---------- 2. Picu udhcpc di klien (via console GNS3) ----------
# Pastikan /tmp/nodes.txt tersedia (dibuat oleh soal1.sh; fallback di bawah
# jika jichi pernah restart dan /tmp kosong).
grep -q . /tmp/nodes.txt 2>/dev/null || {
  TOKEN=$(curl -s -m5 -X POST http://$GH:3080/v3/access/users/authenticate -H 'Content-Type: application/json' \
    -d '{"username":"K-34","password":"K-34@GNS3"}' | jq -r .access_token)
  PIDX=$(curl -s -m5 http://$GH:3080/v3/projects -H "Authorization: Bearer $TOKEN" | jq -r '.[]|select(.name=="K-34-MODUL-3")|.project_id')
  curl -s -m5 http://$GH:3080/v3/projects/$PIDX/nodes -H "Authorization: Bearer $TOKEN" \
    | jq -r '.[]|select(.node_type=="docker")|"\(.name) \(.console)"' > /tmp/nodes.txt
}

# Semua klien memakai image alpinet: busybox udhcpc sudah bawaan,
# tidak perlu install paket apa pun.
#
# Resolver nama: nama resmi soal vs nama node di topologi GNS3 berbeda
# ejaan (itodori, okukatsu, Kusigaki). Fungsi ini menerima keduanya —
# exact/case-insensitive dulu, lalu fallback ke nama node aktual.
resolve() {
  local wanted="$1" found=""
  found=$(awk -v N="$wanted" 'tolower($1)==tolower(N){print $1; exit}' /tmp/nodes.txt)
  if [ -z "$found" ]; then
    case "$(printf '%s' "$wanted" | tr 'A-Z' 'a-z')" in
      itadori)         found=$(awk 'tolower($1)=="itodori"{print $1; exit}'  /tmp/nodes.txt) ;;
      okkotsu|okkatsu) found=$(awk 'tolower($1)=="okukatsu"{print $1; exit}' /tmp/nodes.txt) ;;
      kugisaki)        found=$(awk 'tolower($1)=="kusigaki"{print $1; exit}' /tmp/nodes.txt) ;;
    esac
  fi
  printf '%s' "$found"
}

client() { # client <nama-resmi> — flush IP lalu minta lease baru via relay
  local actual port
  actual=$(resolve "$1")
  [ -z "$actual" ] && { echo "!! $1: node tidak ditemukan di API GNS3"; return; }
  port=$(awk -v N="$actual" '$1==N{print $2}' /tmp/nodes.txt)
  [ -z "$port" ] && { echo "!! $1 ($actual): console tidak ditemukan"; return; }
  {
    sleep 1
    echo "ip addr flush dev eth0; ip link set eth0 up"
    echo "timeout 25 udhcpc -i eth0 -n -q 2>&1 | tail -2"
    echo "ip -br a | grep eth0"
    sleep 25
  } | timeout 50 nc $GH $port &
  echo "  -> $1 (node: $actual) minta lease"
}
echo "--- picu klien Divisi A (Net2, pool soal 4) ---"
client itadori
client fushiguro
client zenin
client okkotsu
echo "--- picu klien Divisi B (Net3, pool soal 5-6) ---"
client ino
client kusakabe
client miwa
client kugisaki   # fixed-address 192.228.3.99 (soal 6)
wait

echo "===== SELESAI: SOAL 3 (jichi) ====="
echo "Cek lease di tengen: grep -E '^lease' /var/lib/dhcp/dhcpd.leases"
echo "Atau jalankan verify3.sh"
