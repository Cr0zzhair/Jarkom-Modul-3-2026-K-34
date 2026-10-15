#!/bin/sh
# SOAL 13 [K-34] — yaga = MariaDB MASTER (Alpine). Jalankan:  sh /root/soal13.sh
# DB db_shibuya_k34 + tabel request_logs + binlog + user repl/api + seed.
# Setelah ini catat File/Position (atau biarkan soal13 inumaki membaca otomatis).
set -u
P="192.228"
DB="db_shibuya_k34"; REPL_PASS="ReplK34!"; API_PASS="ApiK34!"

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
    address ${P}.4.20/24
    gateway ${P}.4.1
EOF
ip addr flush dev eth0 2>/dev/null; ip addr add ${P}.4.20/24 dev eth0; ip link set eth0 up
ip route replace default via ${P}.4.1 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf

apk update || true
apk add mariadb mariadb-client || exit 1
mkdir -p /run/mysqld /var/log/mysql; chown mysql:mysql /run/mysqld /var/log/mysql
[ -f /var/lib/mysql/ibdata1 ] || mariadb-install-db --user=mysql --datadir=/var/lib/mysql

cat > /etc/my.cnf.d/master.cnf <<EOF
[mariadb]
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_format = MIXED
skip-networking = 0
bind-address = 0.0.0.0
EOF

rc-update add mariadb default >/dev/null 2>&1 || true
# alpinet tanpa OpenRC (rc-service tidak ada): kelola proses langsung
if mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
  mysqladmin -u root shutdown 2>/dev/null || true
  sleep 3
fi
mysqld_safe --user=mysql >/tmp/mysqld.log 2>&1 &
i=0; until mysql -u root -e "SELECT 1" >/dev/null 2>&1; do i=$((i+1)); [ $i -ge 30 ] && { echo "!! mariadb tidak ready"; tail -5 /tmp/mysqld.log 2>/dev/null; exit 1; }; sleep 1; done

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${DB};
USE ${DB};
CREATE TABLE IF NOT EXISTS request_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  worker_name VARCHAR(64) NOT NULL,
  client_ip VARCHAR(64) NOT NULL,
  proxy_ip VARCHAR(64) DEFAULT NULL,
  user_agent TEXT DEFAULT NULL,
  uri VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY '${REPL_PASS}';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl'@'%';
CREATE USER IF NOT EXISTS 'api'@'%' IDENTIFIED BY '${API_PASS}';
GRANT ALL ON ${DB}.* TO 'api'@'%';
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;
INSERT INTO ${DB}.request_logs (worker_name, client_ip, uri) VALUES ('yaga-seed','127.0.0.1','/seed');
EOF

echo "===== SELESAI: SOAL 13 MASTER (yaga) ====="
mysql -u root -N -e "SHOW MASTER STATUS;" | tee /root/master-status.txt
ss -tln 2>/dev/null | grep 3306 || netstat -tln 2>/dev/null | grep 3306 || echo "(cek listen 3306 manual)"
