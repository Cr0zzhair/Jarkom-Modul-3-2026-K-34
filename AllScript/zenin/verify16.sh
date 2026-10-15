#!/bin/sh
# K-34 - Soal 16: Automatic Verification

DOMAIN="jujutsu.k34.com"
WWW_DOMAIN="www.jujutsu.k34.com"

echo "=========================================="
echo "       VERIFIKASI SOAL 16"
echo "=========================================="

echo
echo "[INFO] Script dijalankan pada:"
hostname
echo "IP client:"
ip -4 addr show eth0 2>/dev/null | grep inet || true

echo
echo "=== 1. DNS ==="
cat /etc/resolv.conf

if command -v nslookup >/dev/null 2>&1; then
    nslookup -timeout=2 "$DOMAIN" 2>&1
else
    echo "[SKIP] nslookup tidak tersedia"
fi

echo
echo "=== 2. WEB UTAMA: Maki / Panda ==="
i=1
while [ "$i" -le 6 ]; do
    echo "--- Request $i ---"
    curl -sS --connect-timeout 2 --max-time 5 "http://$DOMAIN/" 2>&1
    echo
    i=$((i + 1))
done

echo
echo "=== 3. DOMAIN WWW ==="
curl -sS --connect-timeout 2 --max-time 5 "http://$WWW_DOMAIN/" 2>&1
echo

echo
echo "=== 4. API: Geto -> Nanami / Todo ==="
i=1
while [ "$i" -le 6 ]; do
    echo "--- Request API $i ---"
    curl -sS --connect-timeout 2 --max-time 5 "http://$DOMAIN/api" 2>&1
    echo
    i=$((i + 1))
done

echo
echo "=========================================="
echo "VERIFIKASI SELESAI"
echo "Periksa hostname backend pada respons."
echo "=========================================="
