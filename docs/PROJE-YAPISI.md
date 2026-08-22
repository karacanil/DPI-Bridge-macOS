# Proje yapısı

## Ana bileşenler

```text
Sources/
├── DPIBridge/
│   ├── Models/                  Görünüm, dil tercihi ve yerelleştirme
│   ├── Services/                ByeDPI ve macOS entegrasyonları
│   └── Views/                   SwiftUI ekranları
└── DiscordHTTPProxy/main.c      Discord güncelleyicisi HTTP→SOCKS köprüsü

docs/                            Kullanım, teknik açıklama ve release belgeleri
scripts/                         Geliştirme, doğrulama ve geri alma araçları
byedpi/                          Sabitlenmiş upstream ByeDPI kaynak snapshot'ı
AppIcon.icns                     Uygulama paketinde kullanılan macOS ikonu
AppIcon.iconset/                 İkonun düzenlenebilir kaynak boyutları
DPI-Bridge-Cloudflare-Encrypted-DNS.mobileconfig
                                 İsteğe bağlı DNS over HTTPS profili
```

## Çalışma akışı

`ByeDPIService`, `ciadpi` sürecini doğrudan `Process` API'siyle başlatır. Discord
açılırken ayrıca `discord-http-proxy` yardımcısını çalıştırır:

- Discord/Electron: SOCKS5 `127.0.0.1:1080`
- Discord güncelleyicisi: HTTP CONNECT `127.0.0.1:1081`
- HTTP CONNECT yardımcısının upstream'i: SOCKS5 `127.0.0.1:1080`

ByeDPI'ın varsayılanı tüm ağ arayüzlerinde dinlemek olduğundan uygulama ve
başlatma scripti açıkça `--ip 127.0.0.1` parametresini kullanır.

Yardımcı proxy yalnızca localhost'a bind olur, yalnızca Discord alan adlarına ve
`443` portuna izin verir. TLS trafiğinin içeriğini açmaz veya kaydetmez.

Discord doğrudan DPI Bridge'in child process'i olarak değil, `/usr/bin/open`
üzerinden macOS Launch Services ile başlatılır. Proxy ortam değişkenleri
`open --env` ile Discord'a aktarılır. Bu ayrım Discord'un global kısayollar için
isteyebileceği Input Monitoring izninin DPI Bridge'e atfedilmesini önler.

## Derleme

`Package.swift` iki executable üretir:

- `DPI-Bridge`
- `discord-http-proxy`

`build.sh` varsayılan olarak iki macOS mimarisini içeren universal release
derlemesi yapar. `TARGET_ARCH=x86_64` veya `TARGET_ARCH=arm64` ile tek mimarili
paket de üretilebilir. Script `ciadpi` yardımcısını sabitlenmiş kaynak koddan
yeniden üretir, binary'lerdeki yerel debug yollarını temizler ve DNS profilini
uygulama paketine kopyalar. Ardından yerel test için ad-hoc imza uygular.

Halka açık dağıtımda ad-hoc imza yeterli değildir. Developer ID imzası ve Apple
notarizasyonu için [RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md) kullanılmalıdır.

## Güvenlik ilkeleri

- Kullanıcı girdisi shell komut metnine eklenmez.
- Kalıcı sistem değişiklikleri açık kullanıcı onayı gerektirir.
- Proxy süreçleri uygulama durdurulduğunda kapatılır.
- Uygulama başka süreçleri ad veya port üzerinden zorla kapatmaz.
- Repo telemetri, token veya özel anahtar içermez.
- Doğrulanmamış WireGuard ve düz DNS değiştirme kodu dağıtıma dahil edilmez.
