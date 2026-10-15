#!/bin/bash
# VERIFY 12 — jalankan di client (mis. kusakabe):  bash /root/verify12.sh
# Isi soal 12: A jujutsu.k34.com -> gojo, CNAME www, PTR gojo, forwarder 192.168.122.1,
# dig CNAME/PTR dari client + ping google.com.
P="192.228"; DOMAIN="jujutsu.k34.com"; PASS=0; FAIL=0
ok()  { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }
info(){ echo "[INFO] $1"; }

# --- 0. Siapkan network client otomatis (idempoten, aman diulang) ---
MYIP="$(hostname -s | tr 'A-Z' 'a-z')"
case "$MYIP" in
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
  ip link set eth0 up
  ip route replace default via ${GW}
fi
grep -q "${P}.1.2" /etc/resolv.conf 2>/dev/null || printf "nameserver ${P}.1.2\nnameserver ${P}.1.3\n" > /etc/resolv.conf
echo "--- 0. Client: $(hostname -s) $(ip -br a 2>/dev/null | grep -oE "${P}\.[0-9]+\.[0-9]+" | head -1) ---"

command -v dig >/dev/null || { bad "dig tidak ada"; exit 1; }

echo "--- 1. A record pintu masuk utama -> gojo ---"
A=$(dig +short @${P}.1.2 ${DOMAIN}. 2>/dev/null | head -1)
[ "$A" = "${P}.1.4" ] && ok "${DOMAIN}. = $A (gojo)" || bad "${DOMAIN}. = '${A}' (harap ${P}.1.4)"

echo "--- 2. CNAME www -> domain utama ---"
CNAME=$(dig +short @${P}.1.2 www.${DOMAIN}. 2>/dev/null | head -1)
WIP=$(dig +short @${P}.1.2 www.${DOMAIN}. 2>/dev/null | tail -1)
[ "$CNAME" = "${DOMAIN}." ] && ok "www CNAME -> $CNAME" || bad "www CNAME = '$CNAME' (harap ${DOMAIN}.)"
[ "$WIP" = "${P}.1.4" ] && ok "rantai www berakhir di $WIP (gojo)" || bad "www resolve ke '$WIP' (harap ${P}.1.4)"

echo "--- 3. Reverse DNS: IP gojo -> domain resmi ---"
PTR=$(dig +short -x ${P}.1.4 @${P}.1.2 2>/dev/null | head -1)
[ "$PTR" = "${DOMAIN}." ] && ok "PTR ${P}.1.4 -> $PTR" || bad "PTR = '$PTR' (harap ${DOMAIN}.)"

echo "--- 4. Forwarder ke gateway internet (192.168.122.1) ---"
FWD=$(dig +short @${P}.1.2 google.com 2>/dev/null | head -1)
[ -n "$FWD" ] && ok "google.com via utahime = $FWD (forwarder jalan)" || bad "forwarder gagal (cek NAT jichi & 'forwarders' di utahime)"
ping -c2 -W3 google.com >/dev/null 2>&1 && ok "ping google.com 0% loss (client bisa internet via DNS internal)" || bad "ping google.com gagal"

echo "--- 5. INFO: www menunjuk gojo yang hidup? ---"
if ping -c2 -W3 www.${DOMAIN}. >/dev/null 2>&1; then
  info "ping www OK (gojo .1.4 sudah nyala)"
else
  info "ping www loss TAPI resolve benar -> gojo belum nyala/ada nginx (ranah soal 16, BUKAN salah DNS)"
fi

echo "===== HASIL: $PASS PASS, $FAIL FAIL ====="
