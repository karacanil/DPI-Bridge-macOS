# Proje yapısı

## Ana bileşenler

```text
Sources/
├── SplitWireTurkey/
│   ├── Models/                  Görünüm tercihi
│   ├── Services/                ByeDPI ve macOS entegrasyonları
│   ├── Views/                   SwiftUI ekranları
│   └── Resources/bin/ciadpi     Universal ByeDPI binary
└── DiscordHTTPProxy/main.c      Discord güncelleyicisi HTTP→SOCKS köprüsü

docs/                            Kullanım, teknik açıklama ve release belgeleri
scripts/                         Geliştirme, doğrulama ve geri alma araçları
byedpi/                          Upstream ByeDPI kaynak kodu ve lisansı
AppIcon.icns                     Uygulama paketinde kullanılan macOS ikonu
AppIcon.iconset/                 İkonun düzenlenebilir kaynak boyutları
SplitWire-Cloudflare-Encrypted-DNS.mobileconfig
                                 İsteğe bağlı DNS over HTTPS profili
```

## Çalışma akışı

`ByeDPIService`, `ciadpi` sürecini doğrudan `Process` API'siyle başlatır. Discord
açılırken ayrıca `discord-http-proxy` yardımcısını çalıştırır:

- Discord/Electron: SOCKS5 `127.0.0.1:1080`
- Discord güncelleyicisi: HTTP CONNECT `127.0.0.1:1081`
- HTTP CONNECT yardımcısının upstream'i: SOCKS5 `127.0.0.1:1080`

Yardımcı proxy yalnızca localhost'a bind olur, yalnızca Discord alan adlarına ve
`443` portuna izin verir. TLS trafiğinin içeriğini açmaz veya kaydetmez.

## Derleme

`Package.swift` iki executable üretir:

- `SplitWire-Turkey`
- `discord-http-proxy`

`build.sh` varsayılan olarak iki macOS mimarisini içeren universal release
derlemesi yapar. `TARGET_ARCH=x86_64` veya `TARGET_ARCH=arm64` ile tek mimarili
paket de üretilebilir. Script uygun `ciadpi` mimarisini ve DNS profilini uygulama
paketine kopyalar, ardından yerel test için ad-hoc imza uygular.

Halka açık dağıtımda ad-hoc imza yeterli değildir. Developer ID imzası ve Apple
notarizasyonu için [RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md) kullanılmalıdır.

## Güvenlik ilkeleri

- Kullanıcı girdisi shell komut metnine eklenmez.
- Kalıcı sistem değişiklikleri açık kullanıcı onayı gerektirir.
- Proxy süreçleri uygulama durdurulduğunda kapatılır.
- Uygulama başka süreçleri ad veya port üzerinden zorla kapatmaz.
- Repo telemetri, token veya özel anahtar içermez.
- Doğrulanmamış WireGuard ve düz DNS değiştirme kodu dağıtıma dahil edilmez.
