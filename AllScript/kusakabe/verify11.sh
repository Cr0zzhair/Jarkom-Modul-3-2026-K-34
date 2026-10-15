#!/bin/bash
# VERIFY 11 — jalankan di client (mis. kusakabe):  bash /root/verify11.sh
# Murni soal 11: NS delegasi + SOA serial sama di master & slave (bukti transfer).
# Isi soal 12 (A/CNAME/PTR/forwarder) ada di verify12.sh.
# Syarat: jichi, utahime, shoko started; named jalan di utahime/shoko.
P="192.228"; DOMAIN="jujutsu.k34.com"; PASS=0; FAIL=0
ok()  { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

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

echo "--- 1. NS delegasi di kedua server ---"
NS_M=$(dig @${P}.1.2 ${DOMAIN}. NS +short 2>/dev/null | sort | tr '\n' ' ')
NS_S=$(dig @${P}.1.3 ${DOMAIN}. NS +short 2>/dev/null | sort | tr '\n' ' ')
echo "master NS: $NS_M"
echo "slave  NS: $NS_S"
echo "$NS_M" | grep -q "ns1.${DOMAIN}." && echo "$NS_M" | grep -q "ns2.${DOMAIN}." \
  && ok "master mendelegasikan ns1+ns2" || bad "NS master tidak lengkap ('$NS_M')"
[ "$NS_M" = "$NS_S" ] && [ -n "$NS_M" ] && ok "slave NS sama dengan master" || bad "NS slave beda/kosong"

echo "--- 2. Glue record ns1/ns2 ---"
G1=$(dig +short @${P}.1.2 ns1.${DOMAIN}. 2>/dev/null | head -1)
G2=$(dig +short @${P}.1.2 ns2.${DOMAIN}. 2>/dev/null | head -1)
[ "$G1" = "${P}.1.2" ] && ok "ns1 = $G1 (utahime)" || bad "ns1 = '$G1' (harap ${P}.1.2)"
[ "$G2" = "${P}.1.3" ] && ok "ns2 = $G2 (shoko)" || bad "ns2 = '$G2' (harap ${P}.1.3)"

echo "--- 3. SOA serial (bukti transfer otomatis) ---"
S_M=$(dig @${P}.1.2 ${DOMAIN}. SOA +short 2>/dev/null | awk '{print $3}')
S_S=$(dig @${P}.1.3 ${DOMAIN}. SOA +short 2>/dev/null | awk '{print $3}')
[ -n "$S_M" ] && ok "serial master = $S_M" || bad "SOA master tidak terbaca (named jalan?)"
[ "$S_M" = "$S_S" ] && [ -n "$S_M" ] && ok "serial slave = $S_S (sama, transfer OK)" || bad "serial beda/kosong (master '$S_M' vs slave '$S_S')"

echo "===== HASIL: $PASS PASS, $FAIL FAIL ====="
echo "NOTE: naikkan SERIAL di utahime + reload, verify diulang -> serial slave ikut berubah = transfer otomatis."
