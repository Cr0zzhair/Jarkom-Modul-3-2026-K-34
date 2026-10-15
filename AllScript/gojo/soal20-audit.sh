#!/bin/sh

set -u

ACCESS="/var/log/nginx/access.log"
ERROR="/var/log/nginx/error.log"
OUT="/root/soal20-audit-report.txt"

echo "=== AUDIT SOAL 20 - GOJO ==="

if [ ! -r "$ACCESS" ]; then
    echo "ERROR: Access log tidak ditemukan: $ACCESS"
    exit 1
fi

{
    echo "AUDIT NGINX GOJO"
    date
    echo
    echo "=== RINGKASAN STATUS HTTP ==="

    awk '
    {
        path=$7
        status=$9
        sub(/\?.*/, "", path)

        if (path == "/") {
            total_front++
            front[status]++
        } else if (path == "/api" || path ~ /^\/api\//) {
            total_api++
            api[status]++
        }
    }
    END {
        print "Frontend (/):", total_front+0
        for (s in front) print "  HTTP", s, ":", front[s]

        print "API (/api):", total_api+0
        for (s in api) print "  HTTP", s, ":", api[s]

        print ""
        print "429 rate limit:", api["429"]+0
        print "API 5xx:", api["500"]+api["501"]+api["502"]+api["503"]+api["504"]+api["505"]
        print "API 2xx:", api["200"]+api["201"]+api["202"]+api["204"]
    }' "$ACCESS"

    echo
    echo "=== INDIKASI MASALAH KONEKSI / UPSTREAM ==="

    if [ -r "$ERROR" ]; then
        grep -Ei \
        'connect\(\) failed|upstream timed out|connection refused|no live upstreams|upstream prematurely closed|host not found|could not be resolved' \
        "$ERROR" | tail -n 50 || true
    else
        echo "Error log tidak tersedia."
    fi

    echo
    echo "=== REQUEST API TERBARU ==="
    grep -E '"(GET|HEAD|POST) /api(/|\?| )' "$ACCESS" | tail -n 20 || true

    echo
    echo "Catatan: access log hanya mencakup request yang tercatat."
    echo "RPS dan latency benchmark diambil dari output ApacheBench."
} > "$OUT"

cat "$OUT"

echo
echo "Laporan disimpan di: $OUT"
