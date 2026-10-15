#!/bin/sh
set -eu

CONF="/etc/dhcp/dhcpd.conf"
BACKUP="/etc/dhcp/dhcpd.conf.backup-soal7"

echo "===== SOAL 7: DHCP DIVISI A ====="

# Simpan backup konfigurasi awal
if [ ! -f "$BACKUP" ]; then
    cp "$CONF" "$BACKUP"
fi

# Buat konfigurasi DHCP
cat > "$CONF" <<'EOC'
option domain-name "k34.com";
option domain-search "k34.com";
option domain-name-servers 192.228.1.2, 192.228.1.3;
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
authoritative;

# Network 4: jaringan server DHCP
subnet 192.228.4.0 netmask 255.255.255.0 {
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.228.4.255;
    option routers 192.228.4.1;
}

# Network 2: Divisi A
subnet 192.228.2.0 netmask 255.255.255.0 {
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.228.2.255;
    option routers 192.228.2.1;

    class "pool1" {
        match hardware;
    }
    subclass "pool1" 1:02:42:ca:9e:5b:00; # Itodori
    subclass "pool1" 1:02:42:f5:b9:6b:00; # Fushiguro

    pool {
        allow members of "pool1";
        range 192.228.2.10 192.228.2.35;
    }

    class "pool2" {
        match hardware;
    }
    subclass "pool2" 1:02:42:75:c1:0f:00; # Zenin
    subclass "pool2" 1:02:42:50:8b:a5:00; # Okkotsu (MAC lama, belum diverifikasi)

    pool {
        allow members of "pool2";
        range 192.228.2.70 192.228.2.95;
    }
}

# Network 3: Divisi B
subnet 192.228.3.0 netmask 255.255.255.0 {
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.228.3.255;
    option routers 192.228.3.1;

    pool {
        range 192.228.3.10 192.228.3.199;
    }
}

# Reservasi Kugisaki
host kugisaki {
    hardware ethernet 02:42:2e:cc:bc:00;
    fixed-address 192.228.3.99;
}
EOC

echo "[1] Validasi konfigurasi..."
if ! dhcpd -t -cf "$CONF"; then
    echo "[ERROR] Konfigurasi tidak valid. Memulihkan backup."
    cp "$BACKUP" "$CONF"
    exit 1
fi

echo "[2] Restart DHCP server..."
service isc-dhcp-server restart

echo "[3] Status DHCP server..."
service isc-dhcp-server status

echo "[PASS] Konfigurasi DHCP berhasil diterapkan."
