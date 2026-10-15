#!/bin/bash
P="192.228"

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
    subclass "pool1" 1:02:42:ca:9e:5b:00;
    subclass "pool1" 1:02:42:f5:b9:6b:00;
    pool { allow members of "pool1"; range ${P}.2.10 ${P}.2.35; }

    class "pool2" { match hardware; }
    subclass "pool2" 1:02:42:75:c1:0f:00;
    subclass "pool2" 1:02:42:c9:60:c2:00;
    pool { allow members of "pool2"; range ${P}.2.70 ${P}.2.95; }
}

subnet ${P}.3.0 netmask 255.255.255.0 {
    option routers ${P}.3.1;
    option domain-name-servers ${P}.1.2, ${P}.1.3;
    option domain-name "k34.com";

    class "shortlease" { match hardware; }
    subclass "shortlease" 1:02:42:9c:b1:f3:00;
    subclass "shortlease" 1:02:42:41:9d:c7:00;
    pool {
        allow members of "shortlease";
        range ${P}.3.10 ${P}.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    class "longlease" { match hardware; }
    subclass "longlease" 1:02:42:54:f5:d7:00;
    pool {
        allow members of "longlease";
        range ${P}.3.100 ${P}.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }

    host kugisaki {
        hardware ethernet 02:42:2e:cc:bc:00;
        fixed-address ${P}.3.99;
    }
}
CONF

service isc-dhcp-server restart
echo "Sukses! Konfigurasi Soal 4, 5, dan 6 terpasang permanen."
