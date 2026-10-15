#!/bin/bash
# SOAL 15 [K-34] — jalankan di geto:  bash /root/soal15.sh
# Nginx LB internal: upstream api_cluster (nanami weight=3, todo weight=1) + location /api.
# Murni soal 15 (TANPA backup kirara & healthcheck — itu soal 18).
set -u
P="192.228"

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
    address ${P}.4.2/24
    gateway ${P}.4.1
EOF
ip addr flush dev eth0; ip addr add ${P}.4.2/24 dev eth0; ip link set eth0 up
ip route replace default via ${P}.4.1 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf

apt update || true
apt install -y nginx curl

cat > /etc/nginx/sites-available/geto-api <<EOF
upstream api_cluster {
    server ${P}.4.13 weight=3;   # nanami (3x)
    server ${P}.4.14 weight=1;   # todo (1x)
}

server {
    listen 80;
    server_name api.jujutsu.k34.com jujutsu.k34.com;

    location /api {
        proxy_pass http://api_cluster;
        proxy_set_header Host \$host;
    }

    location / {
        return 404 "geto: hanya melayani /api\n";
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/geto-api /etc/nginx/sites-enabled/geto-api
nginx -t || exit 1
service nginx restart; sleep 1
update-rc.d nginx defaults >/dev/null 2>&1 || true

echo "===== SELESAI: SOAL 15 (geto) ====="
for i in $(seq 1 8); do curl -s -H "Host: api.jujutsu.k34.com" http://127.0.0.1/api/ | grep -o '"worker":"[a-z]*"'; done
