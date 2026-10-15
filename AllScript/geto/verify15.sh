#!/bin/bash
# VERIFY 15 — jalankan di geto:  bash /root/verify15.sh
# Bukti WRR 3:1: 40 request ke /api dari Data Center lokal, rasio nanami:todo = 30:10.
PASS=0; FAIL=0
ok()  { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

command -v curl >/dev/null || { bad "curl tidak ada"; exit 1; }

echo "--- loop 40x GET /api (Host: api.jujutsu.k34.com) ---"
TMP=$(mktemp); FAILN=0
for i in $(seq 1 40); do
  code=$(curl -s -o /tmp/v15body -w "%{http_code}" --max-time 5 -H "Host: api.jujutsu.k34.com" http://127.0.0.1/api/)
  if [ "$code" = "200" ]; then
    grep -o '"worker":"[^"]*"' /tmp/v15body | tr 'A-Z' 'a-z' >> "$TMP"
  else
    echo "request $i: HTTP $code"
    FAILN=$((FAILN+1))
  fi
done
NANAMI=$(grep -c '"worker":"nanami"' "$TMP" || true); NANAMI=${NANAMI:-0}
TODO=$(grep -c '"worker":"todo"' "$TMP" || true); TODO=${TODO:-0}
KIRARA=$(grep -c '"worker":"kirara"' "$TMP" || true); KIRARA=${KIRARA:-0}
echo "nanami=$NANAMI todo=$TODO kirara=$KIRARA gagal=$FAILN (total 40)"
rm -f "$TMP" /tmp/v15body

[ "$FAILN" = "0" ] && ok "40/40 request 200 OK (tidak ada 502)" || bad "$FAILN request gagal"
[ "$KIRARA" = "0" ] && ok "kirara tidak ikut (belum backup, sesuai soal 15)" || bad "kirara ikut menjawab $KIRARA kali"
if [ "$NANAMI" -ge 27 ] && [ "$NANAMI" -le 33 ] && [ "$TODO" -ge 7 ] && [ "$TODO" -le 13 ]; then
  ok "rasio nanami:todo = $NANAMI:$TODO (~3:1)"
else
  bad "rasio $NANAMI:$TODO menyimpang dari 3:1 (harap ~30:10)"
fi

echo "===== HASIL: $PASS PASS, $FAIL FAIL ====="
