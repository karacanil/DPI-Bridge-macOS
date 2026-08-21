# Güvenlik politikası

## Desteklenen sürümler

Yalnızca GitHub Releases bölümünde yayımlanan en güncel sürüm güvenlik
düzeltmeleri alır.

## Güvenlik açığı bildirme

Bir güvenlik açığı bulursan herkese açık issue açma. Repo sahibinin GitHub
**Security → Report a vulnerability** alanını kullan. Özellik etkin değilse,
kişisel veri veya çalışan exploit paylaşmadan maintainer'dan özel iletişim
kanalı iste.

Rapora mümkünse şunları ekle:

- Etkilenen sürüm ve macOS sürümü
- Sorunun tekrarlanma adımları
- Beklenen ve gerçekleşen davranış
- Kişisel bilgi içermeyen log veya ekran görüntüsü
- Önerilen çözüm

Parola, Discord token'ı, çerez, WireGuard özel anahtarı, tam ağ yakalaması veya
başka kişilere ait veri gönderme.

## Güvenlik sınırları

- Yerel proxy'ler `127.0.0.1` dışına bind edilmemelidir.
- HTTP CONNECT köprüsünün Discord alan adı ve `443` kısıtı gevşetilmemelidir.
- Komut satırına kullanıcı girdisi shell metni olarak eklenmemelidir.
- Release paketleri Developer ID ile imzalanmalı, notarize edilmeli ve SHA-256
  özetiyle yayımlanmalıdır.
- Üçüncü taraf `ciadpi` binary'si repodaki kaynaklardan yeniden üretilebilmeli
  ve iki macOS mimarisini içermelidir.

## Log paylaşımı

Loglar alan adları, yerel dosya yolları veya uygulama adları içerebilir. Issue'a
eklemeden önce bu bilgileri maskele. Discord oturum token'ı içeren logları hiçbir
zaman paylaşma.
