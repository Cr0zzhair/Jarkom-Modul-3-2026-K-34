#!/bin/sh
# K-34 - Soal 16: Nginx Reverse Proxy di Gojo

set -eu

FRONTEND_MAKI="192.228.4.11"
FRONTEND_PANDA="192.228.4.12"
API_GETO="192.228.4.2"

DOMAIN="jujutsu.k34.com"
WWW_DOMAIN="www.jujutsu.k34.com"
CONFIG="/etc/nginx/conf.d/jujutsu.conf"

echo "=== Konfigurasi Nginx Soal 16 di Gojo ==="

if ! command -v nginx >/dev/null 2>&1; then
    echo "Nginx belum terpasang, mencoba instalasi..."
    apt-get update
    apt-get install -y nginx
fi

mkdir -p /etc/nginx/conf.d

cat > "$CONFIG" <<EOF
upstream frontend_pool {
    server ${FRONTEND_MAKI}:80;
    server ${FRONTEND_PANDA}:80;
}

upstream api_gateway {
    server ${API_GETO}:80;
}

server {
    listen 80;
    server_name ${DOMAIN} ${WWW_DOMAIN};

    location = /api {
        proxy_pass http://api_gateway;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ^~ /api/ {
        proxy_pass http://api_gateway;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        proxy_pass http://frontend_pool;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "=== Memeriksa konfigurasi ==="
nginx -t

echo "=== Menjalankan Nginx ==="
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable nginx 2>/dev/null || true
fi

if command -v rc-update >/dev/null 2>&1; then
    rc-update add nginx default 2>/dev/null || true
fi

if command -v service >/dev/null 2>&1; then
    service nginx restart
else
    nginx -s reload 2>/dev/null || nginx
fi

echo "=== Status Nginx ==="
nginx -t
echo "Konfigurasi Soal 16 selesai."
