#!/bin/sh

echo "=== SOAL 7: DHCP RELAY ==="

# Hentikan relay sebelumnya
for pid in $(pidof dhcrelay); do
    kill "$pid"
done

sleep 1

# Jalankan relay untuk Network 2, 3, dan 4
dhcrelay -4 -i eth2 -i eth3 -i eth4 192.228.4.10

sleep 1

echo ""
echo "=== Status DHCP Relay ==="
ps aux | grep '[d]hcrelay'
