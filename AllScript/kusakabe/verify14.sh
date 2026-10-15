#!/bin/sh
# VERIFY 14 — dua mode otomatis berdasar hostname:
#  - di CLIENT (Net2/Net3): akses langsung ke worker HARUS ditolak (403/000).
#  - di geto (jalur proxy/LB): akses dengan domain layanan HARUS 200 + hostname/JSON benar.
# Bakteri: sh /root/verify14.sh
P="192.228"; PASS=0; FAIL=0
ok()  { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }
info(){ echo "[INFO] $1"; }
H="$(hostname -s | tr 'A-Z' 'a-z')"
command -v curl >/dev/null || { bad "curl tidak ada (apk add curl / apt install -y curl)"; echo "===== HASIL: $PASS PASS, $FAIL FAIL ====="; exit 1; }
code() { curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$@" 2>/dev/null; }

if [ "$H" = "geto" ]; then
  echo "### MODE geto (jalur allowed) ###"
  for w in "192.228.4.11 maki" "192.228.4.12 panda"; do
    set -- $w; ip=$1; name=$2
    c=$(code -H "Host: jujutsu.k34.com" http://${ip}/)
    body=$(curl -s --max-time 5 -H "Host: jujutsu.k34.com" http://${ip}/ 2>/dev/null | tr 'A-Z' 'a-z')
    [ "$c" = "200" ] && echo "$body" | grep -q "$name" \
      && ok "frontend $name ($ip) via jalur proxy: 200 + hostname" \
      || bad "frontend $name ($ip): code=$c (harap 200 + hostname $name)"
  done
  for w in "192.228.4.13 nanami" "192.228.4.14 todo" "192.228.4.15 kirara"; do
    set -- $w; ip=$1; name=$2
    c=$(code -H "Host: api.jujutsu.k34.com" http://${ip}/api/)
    body=$(curl -s --max-time 5 -H "Host: api.jujutsu.k34.com" http://${ip}/api/ 2>/dev/null)
    echo "$body" | grep -q '"worker"' || { bad "API $name ($ip): code=$c, bukan JSON API"; continue; }
    echo "$body" | grep -qi "$name" && ok "API $name ($ip): 200 + worker=$name" || bad "API $name ($ip): worker mismatch: $body"
    echo "$body" | grep -q '"db_ok":true' \
      && ok "API $name: log tercatat di yaga (db_ok=true)" \
      || bad "API $name: db_ok=false (butuh soal 13: DB yaga + user api)"
  done
  c=$(code http://192.228.4.11/); ([ "$c" = "000" ] || [ "$c" = "403" ]) \
    && ok "host tak dikenal (IP mentah) ditolak: $c" || bad "host tak dikenal lolos: $c"
else
  echo "### MODE client ($(hostname -s), akses langsung harus DITOLAK) ###"
  # 0. network heal khusus client
  case "$H" in
    kusakabe) IP="${P}.3.11"; GW="${P}.3.1" ;;
    ino)      IP="${P}.3.10"; GW="${P}.3.1" ;;
    kusigaki) IP="${P}.3.15"; GW="${P}.3.1" ;;
    miwa)     IP="${P}.3.12"; GW="${P}.3.1" ;;
    itodori)  IP="${P}.2.10"; GW="${P}.2.1" ;;
    fushiguro) IP="${P}.2.11"; GW="${P}.2.1" ;;
    zenin)    IP="${P}.2.12"; GW="${P}.2.1" ;;
    okukatsu) IP="${P}.2.13"; GW="${P}.2.1" ;;
    *)        IP=""; GW="" ;;
  esac
  if [ -n "${IP:-}" ]; then
    ip addr add ${IP}/24 dev eth0 2>/dev/null || true
    ip link set eth0 up; ip route replace default via ${GW}
  fi
  echo "--- 1. Frontend langsung (harus 403/000) ---"
  for ip in ${P}.4.11 ${P}.4.12; do
    c=$(code http://${ip}/)
    ([ "$c" = "403" ] || [ "$c" = "000" ]) && ok "langsung ke $ip ditolak ($c)" || bad "langsung ke $ip LOLOS ($c)"
    c=$(code -H "Host: jujutsu.k34.com" http://${ip}/)
    [ "$c" = "403" ] && ok "dengan domain pun tetap ditolak ($ip)" || bad "$ip + domain lolos ($c)"
  done
  echo "--- 2. API langsung (harus 403/000) ---"
  for ip in ${P}.4.13 ${P}.4.14 ${P}.4.15; do
    c=$(code -H "Host: api.jujutsu.k34.com" http://${ip}/api/)
    ([ "$c" = "403" ] || [ "$c" = "000" ]) && ok "langsung ke API $ip ditolak ($c)" || bad "langsung ke API $ip LOLOS ($c)"
  done
  info "bukti 'via reverse proxy berhasil' butuh soal 15/16: jalankan script ini di geto (sh /root/verify14.sh) -> MODE geto"
fi

echo "===== HASIL: $PASS PASS, $FAIL FAIL ====="
