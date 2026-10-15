#!/bin/sh
set -e

echo "=== SOAL 17: KONFIGURASI GOJO ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Jalankan sebagai root."
    exit 1
fi

FOUND=0
for DIR in /etc/nginx/sites-enabled /etc/nginx/conf.d; do
    [ -d "$DIR" ] || continue

    for FILE in "$DIR"/*; do
        [ -f "$FILE" ] || continue

        if grep -qF '$proxy_add_x_forwarded_for' "$FILE"; then
            cp "$FILE" "$FILE.soal17.bak"
            sed 's/\$proxy_add_x_forwarded_for/\$remote_addr/g' \
                "$FILE.soal17.bak" > "$FILE"
            echo "Header diperbarui: $FILE"
            FOUND=1
        fi
    done
done

if [ "$FOUND" -eq 0 ]; then
    echo "Tidak ditemukan header yang perlu diubah."
fi

if nginx -t; then
    if nginx -s reload; then
        echo "BERHASIL: Konfigurasi Gojo dimuat ulang."
    else
        echo "ERROR: Reload gagal."
        exit 1
    fi
else
    echo "ERROR: Konfigurasi tidak valid. Memulihkan backup."
    for DIR in /etc/nginx/sites-enabled /etc/nginx/conf.d; do
        [ -d "$DIR" ] || continue
        for FILE in "$DIR"/*.soal17.bak; do
            [ -f "$FILE" ] || continue
            ORIGINAL="${FILE%.soal17.bak}"
            cp "$FILE" "$ORIGINAL"
        done
    done
    nginx -t
    exit 1
fi

echo "=== HEADER AKTIF ==="
nginx -T 2>&1 | grep -nE 'X-Real-IP|X-Forwarded-For'
