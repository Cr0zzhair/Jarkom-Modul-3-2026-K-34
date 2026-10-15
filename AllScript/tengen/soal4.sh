#!/bin/bash
P="192.228"

# MAC Address Asli Klien
MAC_I="02:42:ca:9e:5b:00"
MAC_F="02:42:f5:b9:6b:00"
MAC_Z="02:42:75:c1:0f:00"
MAC_O="02:42:c9:60:c2:00"

cat > /etc/dhcp/dhcpd.conf <<CONF
option domain-name "k34.com";
option domain-name-servers ${P}.1.2, ${P}.1.3;
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet ${P}.4.0 netmask 255.255.255.0 { option routers ${P}.4.1; }

subnet ${P}.2.0 netmask 255.255.255.0 {
    option routers ${P}.2.1;

    class "pool1" { match hardware; }
    subclass "pool1" 1:${MAC_I};
    subclass "pool1" 1:${MAC_F};
    pool { allow members of "pool1"; range ${P}.2.10 ${P}.2.35; }

    class "pool2" { match hardware; }
    subclass "pool2" 1:${MAC_Z};
    subclass "pool2" 1:${MAC_O};
    pool { allow members of "pool2"; range ${P}.2.70 ${P}.2.95; }
}

subnet ${P}.3.0 netmask 255.255.255.0 {
    option routers ${P}.3.1;
    pool { range ${P}.3.10 ${P}.3.199; }
}
CONF

service isc-dhcp-server restart
echo "Sukses memasang MAC manual!"
