# Gizlilik

SplitWire Turkey yerel çalışan bir ağ aracıdır. Telemetri, analiz, reklam veya
uzak günlük toplama sistemi içermez.

## Uygulamanın işlemediği veriler

Uygulama şunları okumaz veya saklamaz:

- Discord kullanıcı adı ve parolası
- Mesajlar, sunucular veya arkadaş listesi
- Tarayıcı geçmişi ve çerezler
- Ağ paketlerinin içeriği
- Konum, kişi listesi, kamera veya mikrofon verileri

Yalnızca arayüzün açık/koyu görünüm ve dil tercihleri macOS `UserDefaults`
alanında cihazda saklanır.

## Ağ bağlantıları

- Discord'u açtığında trafik Discord'un kendi sunucularına gider.
- İsteğe bağlı DNS profili, DNS sorgularını HTTPS ile Cloudflare'a gönderir.
- ByeDPI bir VPN değildir ve HTTPS şifrelemesini sonlandırmaz. TLS bağlantısı
  uygulama ile hedef sunucu arasında kalır.

Cloudflare ve Discord kendi gizlilik politikalarına göre bağlantı metadatası
işleyebilir. İnternet sağlayıcısı hedef IP adreslerini görmeye devam edebilir.

## Yerel portlar

- `127.0.0.1:1080`: ByeDPI SOCKS5 proxy
- `127.0.0.1:1081`: Discord güncelleyicisi için HTTP CONNECT köprüsü

Bu portlar yalnızca localhost üzerinde dinler; aynı ağdaki başka cihazlardan
erişilemez. Güncelleyici köprüsü sadece Discord alan adlarına ve `443` portuna
izin verir.

## Klavye ve Input Monitoring izni

SplitWire klavye, fare veya trackpad girdilerini okumaz ve macOS **Input
Monitoring / Giriş İzleme** iznine ihtiyaç duymaz. Discord, sistem genelinde
Push-to-Talk veya başka global tuş kısayolları kullanıldığında kendi adına bu
izni isteyebilir. Bu özellikleri kullanmıyorsan Discord'un isteğini de
reddedebilirsin; metin ve sesli etkinlik modu çalışmaya devam eder.

Beta 3 ve sonrasında Discord macOS Launch Services üzerinden başlatılır. Böylece
Discord'un kendi global kısayol isteği SplitWire'a atfedilmez. Eski Beta 2 ile
SplitWire'a izin verdiysen Sistem Ayarları → Gizlilik ve Güvenlik → Giriş İzleme
altından SplitWire iznini kapatabilirsin.

## Kaldırma

Uygulamayı ve DNS profilini kaldırma adımları
[kullanım kılavuzunda](docs/KULLANIM.md)
dosyasında açıklanır. Uygulama kaldırıldıktan sonra uzak bir hesapta tutulmuş
SplitWire verisi yoktur.
