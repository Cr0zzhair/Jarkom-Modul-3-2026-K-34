# Identitas

| No. | Nama                          | NRP        |
| --- | ----------------------------- | ---------- |
| 1   | Muhammad Syadzili Abdul Muhyi | 5027251030 |
| 2   | Bambang Nasarillah Kurniawan  | 5027251110 |

# Pengerjaan
![[Pasted image 20261014205321.png]]
Di sini kami membuat topologi jaringan sesuai dengan yang diminta oleh soal, yaitu dengan menggunakan beberapa konfigurasi berikut:

- **NAT1**: Digunakan sebagai penghubung jaringan internal dengan jaringan eksternal.
    
- **Jichi**: Digunakan sebagai node pusat yang menghubungkan NAT1 dengan beberapa cabang jaringan internal.
    
- **Switch1**: Menghubungkan node Jichi dengan Shoko, Utahime, dan Gojo.
    
- **Switch2**: Menghubungkan Jichi dengan Switch3 dan Switch9.
    
- **Switch3**: Menghubungkan jaringan client Itodori dan Kushiguro.
    
- **Switch9**: Menghubungkan jaringan client Zenin dan Okukatsu.
    
- **Switch4**: Menghubungkan Jichi dengan Switch5 dan Switch8.
    
- **Switch5**: Menghubungkan jaringan client Kusakabe dan Ino.
    
- **Switch8**: Menghubungkan jaringan client Miwa dan Kugisaki.
    
- **Switch6**: Menghubungkan Jichi dengan Switch7 dan Switch10.
    
- **Switch7**: Menghubungkan Geto serta client Maki, Panda, Nanami, dan Kirara, termasuk satu client lain yang labelnya kurang terbaca pada gambar.
    
- **Switch10**: Menghubungkan node Tengen dengan client Yaga dan Inumaki.
    

Topologi ini dirancang untuk menghubungkan seluruh node dan client melalui beberapa cabang jaringan. Komunikasi antarnode bergantung pada konfigurasi alamat IP, subnet, gateway, dan routing yang diterapkan.

1.