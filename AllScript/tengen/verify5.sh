#!/bin/bash
P="192.228"; PASS=0; FAIL=0
ok()  { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }
C=/etc/dhcp/dhcpd.conf
L=/var/lib/dhcp/dhcpd.leases

echo "--- Cek Deklarasi Pool & Options ---"
grep -q "range ${P}.3.10 ${P}.3.89"   "$C" && ok "pool short lease .3.10-.3.89"   || bad "pool short hilang"
grep -q "range ${P}.3.100 ${P}.3.199" "$C" && ok "pool long lease .3.100-.3.199" || bad "pool long hilang"
grep -A5 'class "shortlease"' "$C" | grep -q "default-lease-time 1800" && ok "short lease = 1800s (30 menit)" || bad "short lease bukan 1800"
grep -A5 'class "longlease"'  "$C" | grep -q "default-lease-time 43200" && ok "long lease = 43200s (12 jam)"  || bad "long lease bukan 43200"
grep -q "domain-name-servers ${P}.1.2, ${P}.1.3" "$C" && ok "option DNS .1.2 & .1.3" || bad "option DNS hilang"
grep -q 'domain-name "k34.com"' "$C" && ok "domain-search k34.com" || bad "domain-name hilang"

echo "--- Cek Durasi Lease Aktual Klien ---"
lease_time() {
  awk -v m="$1" 'BEGIN{RS="}"} $0 ~ ("hardware ethernet " m ";") && /binding state active/ {
    if (match($0, /ends [0-6] ([0-9]+)\/([0-9]+)\/([0-9]+) ([0-9]+):([0-9]+):([0-9]+);/, e) && \
       match($0, /starts [0-6] ([0-9]+)\/([0-9]+)\/([0-9]+) ([0-9]+):([0-9]+):([0-9]+);/, s)) {
      print mktime(e[1]" "e[2]" "e[3]" "e[4]" "e[5]" "e[6]) - mktime(s[1]" "s[2]" "s[3]" "s[4]" "s[5]" "s[6]);
    }}' "$L" | tail -1
}

ino=$(lease_time "02:42:9c:b1:f3:00"); kus=$(lease_time "02:42:41:9d:c7:00"); miwa=$(lease_time "02:42:54:f5:d7:00")

[ "$ino" = "1800" ] && ok "ino: durasi lease $ino s" || bad "ino: durasi lease ${ino:-kosong} (harus 1800)"
[ "$kus" = "1800" ] && ok "kusakabe: durasi lease $kus s" || bad "kusakabe: durasi lease ${kus:-kosong} (harus 1800)"
[ "$miwa" = "43200" ] && ok "miwa: durasi lease $miwa s" || bad "miwa: durasi lease ${miwa:-kosong} (harus 43200)"

echo "===== HASIL: $PASS PASS, $FAIL FAIL ====="
