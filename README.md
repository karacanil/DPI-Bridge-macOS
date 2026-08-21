# SplitWire Turkey for macOS

SplitWire Turkey, Discord'a erişimde kullanılan açık kaynaklı bir macOS
uygulamasıdır. ByeDPI'ı yönetir, Discord'u gerekli proxy ayarlarıyla başlatır ve
Discord güncelleyicisinin **Checking for Updates** ekranında kalmasını önlemek
için yerel bir bağlantı köprüsü çalıştırır.

Uygulama hesap parolası, mesaj, çerez veya ağ trafiği kaydetmez.

## Kolay kurulum

Geliştirici araçlarına veya Python'a ihtiyaç yoktur.

1. GitHub sayfasındaki **Releases** bölümünden son `.zip` dosyasını indir.
2. Zip'i aç ve `SplitWire-Turkey.app` dosyasını **Applications** klasörüne taşı.
3. Uygulamaya sağ tıklayıp **Aç** seçeneğini kullan.
4. Uygulamada **Şifreli DNS Profilini Aç** düğmesine bas.
5. Sistem Ayarları → Genel → Aygıt Yönetimi altında profili bir kez yükle.
6. Ana ekrandaki **Discord** düğmesine bas.

Şifreli DNS profili yalnızca alan adı çözümlemeyi Cloudflare DNS over HTTPS'e
taşır. Profil kaldırılabilir; parola veya kullanıcıya özel bilgi içermez.

## Nasıl çalışır?

```text
Discord ──SOCKS5──▶ ByeDPI (127.0.0.1:1080) ──▶ İnternet

Discord güncelleyicisi ──HTTP CONNECT (127.0.0.1:1081)
                                      │
                                      └──▶ ByeDPI

DNS sorguları ──şifreli DNS──▶ Cloudflare
```

İki yerel proxy yalnızca bilgisayarın kendisinden erişilebilen `127.0.0.1`
adresinde dinler. Güncelleyici köprüsü yalnızca Discord alan adlarına ve HTTPS
portu `443`e izin verir.

Teknik ayrıntılar ve elle yeniden üretim adımları için
[Discord bağlantı çözümü](DISCORD-BAGLANTI-COZUMU.md) belgesine bak.

## Kaldırma ve eski ayarlara dönme

Uygulamada ByeDPI'ı durdurup uygulamadan çık. Ardından:

1. Sistem Ayarları → Genel → Aygıt Yönetimi bölümünü aç.
2. **SplitWire Cloudflare Encrypted DNS** profilini kaldır.
3. `SplitWire-Turkey.app` dosyasını Applications klasöründen sil.

Kaynak koddan yardımcı scriptleri kullandıysan:

```bash
./scripts/restore-discord-network.sh
```

Tam geri alma ve doğrulama adımları
[rehberde](DISCORD-BAGLANTI-COZUMU.md#durdurma-ve-tam-geri-alma) bulunur.

## Sistem gereksinimleri

- macOS 13 Ventura veya daha yeni sürüm
- Intel veya Apple Silicon Mac
- `/Applications/Discord.app` altında kurulu Discord

## Kaynaktan derleme

Gereksinimler: Xcode Command Line Tools ve Swift 5.9 veya daha yeni sürüm.

```bash
git clone <fork-adresi>
cd SplitWire-Turkey-macOS
./build.sh
open SplitWire-Turkey.app
```

`build.sh`, Intel ve Apple Silicon için universal uygulama üretir ve yerel
geliştirme için ad-hoc imzalar. Halka açık release'ler Developer ID ile
imzalanmalı ve Apple tarafından notarize edilmelidir; ayrıntılar
[yayın kontrol listesinde](RELEASE-CHECKLIST.md) yer alır.

## Gizlilik ve güvenlik

- Telemetri ve analitik yoktur.
- Uygulama ağ içeriğini kaydetmez.
- Proxy'ler dış ağ arayüzlerinde değil, yalnızca localhost üzerinde dinler.
- Şifreli DNS profili kullanıcı tarafından açıkça kurulur ve kaldırılabilir.
- Hassas logları issue'lara yüklemeden önce kişisel bilgileri temizlemek gerekir.

Ayrıntılar: [PRIVACY.md](PRIVACY.md) ve [SECURITY.md](SECURITY.md).

## Proje durumu

Bu sürüm doğrulanmış ByeDPI + Discord bağlantısına odaklanır. Eski deneysel
WireGuard ve düz DNS değiştirme bileşenleri, genel sürümde beklenmeyen sistem
değişikliği oluşturmamaları için kaldırılmıştır.

## Katkı ve kaynaklar

Bu çalışma, SplitWire Turkey macOS projesi ve orijinal SplitWire Turkey
projesinden türetilmiştir. ByeDPI/ciadpi kaynak kodunu kullanır. İlgili telif ve
lisans bildirimleri korunmuştur.

- [Orijinal SplitWire Turkey](https://github.com/cagritaskn/SplitWire-Turkey)
- [ByeDPI](https://github.com/hufrea/byedpi)

Katkılar pull request ile gönderilebilir. Güvenlik açıkları için herkese açık
issue yerine [SECURITY.md](SECURITY.md) içindeki yöntemi kullan.

## Lisans

Proje [MIT Lisansı](LICENSE) ile dağıtılır. `byedpi/` altındaki üçüncü taraf kod
kendi lisans bildirimine tabidir.
