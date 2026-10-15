#!/bin/sh
# SOAL 14 [K-34] — generic worker (Alpine): maki/panda = frontend, nanami/todo/kirara = API.
# Jalankan di tiap worker:  sh /root/soal14.sh
# Frontend: HTML + hostname. API: JSON + catat ke db_shibuya_k34.request_logs di yaga.
# Batasan: frontend hanya dari gojo (.1.4) & Net4; API hanya dari geto (.4.2); host tak dikenal -> 444.
set -u
P="192.228"
DBH="${P}.4.20"; DB="db_shibuya_k34"; DBU="api"; DBP="ApiK34!"
H="$(hostname -s | tr 'A-Z' 'a-z')"
case "$H" in
  maki)    IP="${P}.4.11"; ROLE=frontend ;;
  panda)   IP="${P}.4.12"; ROLE=frontend ;;
  nanami)  IP="${P}.4.13"; ROLE=api ;;
  todo)    IP="${P}.4.14"; ROLE=api ;;
  kirara)  IP="${P}.4.15"; ROLE=api ;;
  *) echo "!! hostname $(hostname -s) bukan worker (maki/panda/nanami/todo/kirara)"; exit 1 ;;
esac

# 0. IP persisten + live
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
    address ${IP}/24
    gateway ${P}.4.1
EOF
ip addr flush dev eth0 2>/dev/null; ip addr add ${IP}/24 dev eth0; ip link set eth0 up
ip route replace default via ${P}.4.1 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 1. Paket: nginx + php-fpm + mysqli (deteksi versi PHP Alpine otomatis)
apk update || true
apk add nginx curl || exit 1
PHPV=""
for v in 84 83 82 81; do
  if apk add "php$v-fpm" "php$v-mysqli" >/dev/null 2>&1; then PHPV="$v"; break; fi
done
[ -z "$PHPV" ] && { echo "!! php-fpm/php-mysqli tidak ketemu di repo"; exit 1; }
echo ">> PHP versi ${PHPV}, role ${ROLE}"

mkdir -p /var/www/html

# 2. Konten per role
if [ "$ROLE" = "frontend" ]; then
cat > /var/www/html/index.php <<'PHP'
<?php $host = gethostname(); $srv = $_SERVER['SERVER_ADDR'] ?? '?'; ?>
<!DOCTYPE html><html><body style="font-family:sans-serif;text-align:center;padding-top:40px">
<h1>Frontend worker: <?php echo htmlspecialchars($host); ?></h1>
<p>IP: <?php echo htmlspecialchars($srv); ?> - Jujutsu High Network [K-34]</p>
</body></html>
PHP
rm -f /var/www/html/api.php
DOMAINS="jujutsu.k34.com www.jujutsu.k34.com"
ALLOW="allow 127.0.0.1;\n    allow ${P}.1.4;\n    allow ${P}.4.0/24;"
else
cat > /var/www/html/api.php <<PHP
<?php
header('Content-Type: application/json');
\$worker = gethostname();
\$client_ip = isset(\$_SERVER['HTTP_X_REAL_IP']) ? \$_SERVER['HTTP_X_REAL_IP'] : '';
if (\$client_ip === '' && isset(\$_SERVER['HTTP_X_FORWARDED_FOR'])) {
  \$p = explode(',', \$_SERVER['HTTP_X_FORWARDED_FOR']); \$client_ip = trim(\$p[0]);
}
if (\$client_ip === '') \$client_ip = isset(\$_SERVER['REMOTE_ADDR']) ? \$_SERVER['REMOTE_ADDR'] : 'unknown';
\$proxy_ip = isset(\$_SERVER['REMOTE_ADDR']) ? \$_SERVER['REMOTE_ADDR'] : '';
\$ua  = isset(\$_SERVER['HTTP_USER_AGENT']) ? \$_SERVER['HTTP_USER_AGENT'] : '';
\$uri = isset(\$_SERVER['REQUEST_URI']) ? \$_SERVER['REQUEST_URI'] : '';
\$db_ok = false;
try {
  \$m = @new mysqli('${DBH}','${DBU}','${DBP}','${DB}');
  if (!\$m->connect_error) {
    \$st = \$m->prepare("INSERT INTO request_logs (worker_name,client_ip,proxy_ip,user_agent,uri) VALUES (?,?,?,?,?)");
    if (\$st) { \$st->bind_param('sssss',\$worker,\$client_ip,\$proxy_ip,\$ua,\$uri); \$st->execute(); \$db_ok = \$st->affected_rows > 0; \$st->close(); }
    \$m->close();
  }
} catch (Throwable \$e) { \$db_ok = false; }
echo json_encode(['worker'=>\$worker,'client_ip'=>\$client_ip,'proxy_ip'=>\$proxy_ip,'uri'=>\$uri,'db_ok'=>\$db_ok]);
PHP
rm -f /var/www/html/index.php
DOMAINS="api.jujutsu.k34.com jujutsu.k34.com"
ALLOW="allow 127.0.0.1;\n    allow ${P}.4.2;"
fi
chmod 644 /var/www/html/*.php

# 3. Nginx: blokir host tak dikenal (444) + vhost domain layanan + allow/deny jalur proxy
printf '%b' "$ALLOW" > /tmp/allow.txt
ALLOWRULES="$(cat /tmp/allow.txt)"
if [ "$ROLE" = "frontend" ]; then
  FALLBACK="/index.php?\$query_string"
else
  FALLBACK="/api.php?\$query_string"
fi
cat > /etc/nginx/http.d/worker.conf <<EOF
server {
    listen 80 default_server;
    server_name _;
    return 444;
}
server {
    listen 80;
    server_name ${DOMAINS};
    root /var/www/html;
    index index.php api.php;
    ${ALLOWRULES}
    deny all;
    location / {
        try_files \$uri \$uri/ ${FALLBACK};
    }
    location ~ \.php\$ {
        fastcgi_pass 127.0.0.1:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
rm -f /etc/nginx/http.d/default.conf
nginx -t || exit 1

# 4. Start service (OpenRC kalau ada, fallback langsung)
rc-update add nginx default >/dev/null 2>&1 || true
rc-service nginx restart >/dev/null 2>&1 || { nginx -s stop 2>/dev/null; nginx; }
rc-update add php-fpm${PHPV} default >/dev/null 2>&1 || true
rc-service php-fpm${PHPV} restart >/dev/null 2>&1 || php-fpm${PHPV} 2>/dev/null || true
sleep 2
ps aux | grep -v grep | grep -E "nginx|php-fpm" | head -4

# 5. Uji lokal (loopback = jalur allowed)
echo "===== SELESAI: SOAL 14 ${H} (${IP}, ${ROLE}) ====="
if [ "$ROLE" = "frontend" ]; then
  curl -s -H "Host: jujutsu.k34.com" http://127.0.0.1/ | head -5
else
  curl -s -H "Host: api.jujutsu.k34.com" http://127.0.0.1/api/ ; echo
fi
