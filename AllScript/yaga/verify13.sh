#!/bin/sh
# VERIFY 13 — jalankan di yaga:  sh /root/verify13.sh
# Bukti: binlog master ON, slave konek (server-id 2, read_only),
# user remote ada, dan INSERT di master muncul di slave (uji replikasi live).
P="192.228"; DB="db_shibuya_k34"; API_PASS="ApiK34!"; SLAVE="${P}.4.21"
PASS=0; FAIL=0
ok()  { echo "[PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

echo "--- 1. Binary logging master ---"
LB=$(mysql -u root -N -e "SHOW VARIABLES LIKE 'log_bin';" 2>/dev/null | awk '{print $2}')
SID=$(mysql -u root -N -e "SELECT @@server_id;" 2>/dev/null)
[ "$LB" = "ON" ] && ok "log_bin = ON" || bad "log_bin = '$LB' (harap ON)"
[ "$SID" = "1" ] && ok "server-id master = 1" || bad "server-id = '$SID' (harap 1)"
MS=$(mysql -u root -N -e "SHOW MASTER STATUS;" 2>/dev/null | head -1)
[ -n "$MS" ] && ok "SHOW MASTER STATUS: $MS" || bad "SHOW MASTER STATUS kosong"

echo "--- 2. Database + tabel + user remote ---"
mysql -u root -N -e "SHOW DATABASES;" 2>/dev/null | grep -qx "$DB" \
  && ok "database $DB ada" || bad "database $DB hilang"
mysql -u root -N -e "SHOW TABLES IN $DB;" 2>/dev/null | grep -qx "request_logs" \
  && ok "tabel request_logs ada" || bad "tabel request_logs hilang"
mysql -u root -N -e "SELECT user,host FROM mysql.user;" 2>/dev/null | grep -q "api.*%" \
  && ok "user api@'%' ada (akses Net4)" || bad "user api@'%' hilang"
mysql -u root -N -e "SELECT user,host FROM mysql.user;" 2>/dev/null | grep -q "repl.*%" \
  && ok "user repl@'%' ada (replikasi)" || bad "user repl@'%' hilang"

echo "--- 3. Slave hidup (server-id 2, read_only) ---"
SSID=$(mysql -h ${SLAVE} -u api -p"${API_PASS}" -N -e "SELECT @@server_id;" 2>/dev/null)
SRO=$(mysql -h ${SLAVE} -u api -p"${API_PASS}" -N -e "SELECT @@read_only;" 2>/dev/null)
[ "$SSID" = "2" ] && ok "slave server-id = 2" || bad "slave server-id = '$SSID'"
[ "$SRO" = "1" ] && ok "slave read_only = ON" || bad "slave read_only = '$SRO'"

echo "--- 4. Replikasi live: INSERT master -> SELECT slave ---"
MARK="verify13-$(date +%s)"
mysql -u root -e "INSERT INTO ${DB}.request_logs (worker_name,client_ip,uri) VALUES ('$MARK','9.9.9.9','/verify13');" 2>/dev/null \
  && ok "INSERT marker '$MARK' di master" || bad "INSERT di master gagal"
sleep 3
HIT=$(mysql -h ${SLAVE} -u api -p"${API_PASS}" -N -e "SELECT COUNT(*) FROM ${DB}.request_logs WHERE worker_name='$MARK';" 2>/dev/null)
[ "$HIT" = "1" ] && ok "marker muncul di slave (replikasi realtime OK)" || bad "marker TIDAK di slave (count='$HIT')"

echo "===== HASIL: $PASS PASS, $FAIL FAIL ====="
