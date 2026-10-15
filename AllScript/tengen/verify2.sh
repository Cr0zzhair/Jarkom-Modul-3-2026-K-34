#!/bin/bash
# VERIFY 2 — jalankan di tengen:  bash /root/verify2.sh
P="192.228"; PASS=0; FAIL=0
ok()  { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

ip -br a | grep -q "eth0.*${P}.4.10/24" && ok "IP tengen = ${P}.4.10" || bad "IP tengen salah"
dhcpd -t -cf /etc/dhcp/dhcpd.conf >/dev/null 2>&1 && ok "dhcpd.conf valid" || bad "dhcpd.conf invalid"
ps aux | grep -v grep | grep -q dhcpd && ok "service dhcpd running" || bad "dhcpd tidak jalan"
ss -lun | grep -q ':67 ' && ok "listen udp/67" || bad "port 67 tidak dibuka"

grep -qi "no subnet" <(dhcpd -t -cf /etc/dhcp/dhcpd.conf 2>&1) \
  && bad "ada 'No subnet declaration'" || ok "tanpa 'No subnet declaration'"

grep -q "subnet ${P}.4.0"  /etc/dhcp/dhcpd.conf && ok "Net4 dideklarasikan (subnet lokal)" || bad "Net4 tidak dideklarasikan"
grep -q "subnet ${P}.2.0"  /etc/dhcp/dhcpd.conf && ok "scope Net2 ada"   || bad "scope Net2 hilang"
grep -q "subnet ${P}.3.0"  /etc/dhcp/dhcpd.conf && ok "scope Net3 ada"   || bad "scope Net3 hilang"
grep -A2 "subnet ${P}.4.0" /etc/dhcp/dhcpd.conf | grep -q range \
  && bad "Net4 punya pool (harusnya tidak)" || ok "Net4 tanpa pool dinamis"

echo "===== HASIL: $PASS PASS, $FAIL FAIL ====="
