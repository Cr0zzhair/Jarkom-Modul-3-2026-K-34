#!/bin/bash
# VERIFY 1 (Dimodifikasi) — jalankan di jichi:  bash /root/verify1.sh
P="192.228"; PASS=0; FAIL=0
ok()   { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad()  { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }
info() { echo -e "\n--- $1 ---"; }

info "1. Pengecekan IP Gateway & WAN Jichi"
ip -br a | grep -q "eth1.*${P}.1.1/24"  && ok "eth1 = ${P}.1.1 (Net1)"  || bad "eth1 bukan ${P}.1.1"
ip -br a | grep -q "eth2.*${P}.2.1/24"  && ok "eth2 = ${P}.2.1 (Net2)"  || bad "eth2 bukan ${P}.2.1"
ip -br a | grep -q "eth3.*${P}.3.1/24"  && ok "eth3 = ${P}.3.1 (Net3)"  || bad "eth3 bukan ${P}.3.1"
ip -br a | grep -q "eth4.*${P}.4.1/24"  && ok "eth4 = ${P}.4.1 (Net4)"  || bad "eth4 bukan ${P}.4.1"
ip -br a | grep -q "eth0.*192.168.122." && ok "eth0 WAN dari NAT"       || bad "eth0 tidak dapat IP NAT"

info "2. Pengecekan Routing (Forwarding & SNAT)"
[ "$(sysctl -n net.ipv4.ip_forward)" = "1" ] && ok "ip_forward = 1" || bad "ip_forward != 1"
iptables -t nat -L POSTROUTING -n | grep -q MASQUERADE && ok "SNAT/MASQUERADE ada" || bad "MASQUERADE tidak ada"

info "3. Pengecekan Ping Host Statis Server (Harus PASS di Soal 1)"
for ip in 1.2 1.3 1.4 4.10 4.2 4.11 4.12 4.13 4.14 4.15 4.20 4.21 2.1 3.1; do
  ping -c1 -W1 ${P}.${ip} >/dev/null 2>&1 && ok "ping ${P}.${ip}" || bad "ping ${P}.${ip}"
done

info "4. Pengecekan Akses Internet"
ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 && ok "ping 8.8.8.8 (internet)" || bad "internet gagal"

info "5. Pengecekan Ping Client DHCP (Wajar FAIL jika Soal 2 & 3 belum dikerjakan)"
for ip in 2.10 2.11 2.70 2.71 3.10 3.11 3.99 3.100; do
  ping -c1 -W1 ${P}.${ip} >/dev/null 2>&1 && ok "ping ${P}.${ip}" || bad "ping ${P}.${ip}"
done

echo -e "\n===== HASIL: $PASS PASS, $FAIL FAIL ====="
echo "*Catatan: Jika 8 FAIL hanya berasal dari poin 5, maka Soal 1 kamu SUDAH BENAR."
