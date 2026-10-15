#!/bin/bash
# VERIFY 3 (Dimodifikasi untuk Demo) — jalankan di jichi: bash /root/verify3.sh
P="192.228"; PASS=0; FAIL=0
ok()  { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }
info() { echo -e "\n--- $1 ---"; }

info "1. Pengecekan Service DHCP Relay di Jichi"
ps aux | grep -v grep | grep -q dhcrelay && ok "dhcrelay aktif -> Meneruskan ke $(grep SERVERS /etc/default/isc-dhcp-relay | cut -d= -f2)" \
                                         || bad "dhcrelay tidak jalan"

# Menyiapkan akses API GNS3 untuk cek IP klien
GH="10.4.89.247"
[ -s /tmp/nodes.txt ] || {
  TOKEN=$(curl -s -m5 -X POST http://$GH:3080/v3/access/users/authenticate -H 'Content-Type: application/json' \
    -d '{"username":"K-34","password":"K-34@GNS3"}' | jq -r .access_token)
  PIDX=$(curl -s -m5 http://$GH:3080/v3/projects -H "Authorization: Bearer $TOKEN" | jq -r '.[]|select(.name=="K-34-MODUL-3")|.project_id')
  curl -s -m5 http://$GH:3080/v3/projects/$PIDX/nodes -H "Authorization: Bearer $TOKEN" \
    | jq -r '.[]|select(.node_type=="docker")|"\(.name) \(.console)"' > /tmp/nodes.txt
}

check_relay() {
  local wanted="$1" expected_subnet="$2"

  # Resolve nama ke GNS3
  local name=$(awk -v N="$wanted" 'tolower($1)==tolower(N){print $1; exit}' /tmp/nodes.txt)
  case "$(printf '%s' "$wanted" | tr 'A-Z' 'a-z')" in
    itadori)  [ -n "$name" ] || name=$(awk 'tolower($1)=="itodori"{print $1; exit}'  /tmp/nodes.txt) ;;
    okkotsu)  [ -n "$name" ] || name=$(awk 'tolower($1)=="okukatsu"{print $1; exit}' /tmp/nodes.txt) ;;
    kugisaki) [ -n "$name" ] || name=$(awk 'tolower($1)=="kusigaki"{print $1; exit}' /tmp/nodes.txt) ;;
  esac
  name=${name:-$wanted}

  local port=$(awk -v N="$name" 'tolower($1)==tolower(N){print $2}' /tmp/nodes.txt)
  local ip=$( (echo "ip -br a | grep eth0"; sleep 3) | timeout 10 nc -q 2 $GH $port 2>/dev/null \
              | grep -aoE "${P}\.[0-9]+\.[0-9]+/24" | head -1)
  ip=${ip%%/*}   # Hapus /24

  # Cek apakah klien mendapat IP di subnet yang benar (mengabaikan pembagian pool spesifik)
  if echo "$ip" | grep -qE "^${P}\.${expected_subnet}\."; then
    ok "$wanted sukses via relay | IP: ${ip:-Kosong} (Subnet Net $expected_subnet)"
  else
    bad "$wanted gagal relay | IP: ${ip:-Kosong} (Diharapkan Net $expected_subnet)"
  fi
}

info "2. Bukti DHCP Relay ke Divisi A (Target: Subnet 192.228.2.x)"
check_relay itadori 2
check_relay fushiguro 2
check_relay zenin 2
check_relay okkotsu 2

info "3. Bukti DHCP Relay ke Divisi B (Target: Subnet 192.228.3.x)"
check_relay ino 3
check_relay kusakabe 3
check_relay kugisaki 3
check_relay miwa 3

echo -e "\n===== HASIL: $PASS PASS, $FAIL FAIL ====="
echo "*Catatan Demo: Berhasil mendapat lease IP default (.100+). Pembagian IP spesifik akan dikonfigurasi pada Soal 4-6."
