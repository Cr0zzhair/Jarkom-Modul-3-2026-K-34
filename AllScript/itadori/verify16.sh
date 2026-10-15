#!/bin/sh
# Verifikasi Soal 16 dari client

DOMAIN="jujutsu.k34.com"
WWW_DOMAIN="www.jujutsu.k34.com"

echo "=== SOAL 16: VERIFIKASI ==="

echo
echo "=== 1. Cek DNS menggunakan nslookup ==="
if command -v nslookup >/dev/null 2>&1; then
    nslookup -timeout=2 "$DOMAIN"
    nslookup -timeout=2 "$WWW_DOMAIN"
else
    echo "nslookup tidak tersedia; DNS dilewati."
fi

echo
echo "=== 2. Cek HTTP domain utama ==="
i=1
while [ "$i" -le 6 ]; do
    echo "Request $i:"
    curl --connect-timeout 2 --max-time 5 -sS \
        -w "\nHTTP Status: %{http_code}\n" \
        "http://${DOMAIN}/" || echo "Request gagal"
    i=$((i + 1))
done

echo
echo "=== 3. Cek HTTP domain www ==="
curl --connect-timeout 2 --max-time 5 -sS \
    -w "\nHTTP Status: %{http_code}\n" \
    "http://${WWW_DOMAIN}/" || echo "Request www gagal"

echo
echo "=== 4. Cek API ==="
i=1
while [ "$i" -le 6 ]; do
    echo "Request API $i:"
    curl --connect-timeout 2 --max-time 5 -sS \
        -w "\nHTTP Status: %{http_code}\n" \
        "http://${DOMAIN}/api" || echo "Request API gagal"
    i=$((i + 1))
done

echo
echo "=== SELESAI ==="
