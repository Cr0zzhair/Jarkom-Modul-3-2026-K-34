#!/bin/sh

set -e

echo "=================================="
echo " SOAL 20 - BENCHMARK SHIBUYA"
echo "=================================="

echo "[1/4] Update package..."
apk update

echo "[2/4] Install Apache Benchmark..."
apk add apache2-utils

echo "[3/4] Verifikasi Apache Benchmark..."
if ! command -v ab >/dev/null 2>&1; then
    echo "ERROR: Perintah ab belum tersedia."
    exit 1
fi

ab -V

echo "[4/4] Menjalankan benchmark..."

if ! ping -c 1 jujutsu.k34.com >/dev/null 2>&1; then
    echo "PERINGATAN: Domain tidak merespons ping."
    echo "Tetap mencoba HTTP benchmark..."
fi

echo
echo "=== BASELINE FRONTEND ==="
ab -n 600 -c 30 \
   -g /tmp/soal20-frontend.tsv \
   http://jujutsu.k34.com/ \
   > /tmp/soal20-frontend.txt 2>&1 || true
cat /tmp/soal20-frontend.txt

echo
echo "=== BENCHMARK API ==="
ab -n 600 -c 30 \
   -g /tmp/soal20-api.tsv \
   http://jujutsu.k34.com/api/ \
   > /tmp/soal20-api.txt 2>&1 || true
cat /tmp/soal20-api.txt

echo
echo "=== FILE HASIL ==="
echo "/tmp/soal20-frontend.txt"
echo "/tmp/soal20-api.txt"
echo
echo "Benchmark selesai."
