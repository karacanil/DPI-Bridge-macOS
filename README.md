# SplitWire Turkey for macOS

SplitWire Turkey, macOS üzerinde Discord bağlantısı için geliştirilmiş açık
kaynaklı bir yardımcı uygulamadır. Bu fork tek bir doğrulanmış akışa odaklanır:

- zehirlenmiş DNS yanıtlarını şifreli DNS profiliyle aşmak,
- Discord/Electron trafiğini ByeDPI SOCKS5 proxy'sinden geçirmek,
- Discord güncelleyicisinin **Checking for Updates** ekranında kalmasını yerel
  HTTP→SOCKS köprüsüyle önlemek.

Uygulama hesap parolası, mesaj, çerez veya ağ trafiği kaydetmez.

## Kolay kurulum

Geliştirici araçlarına veya Python'a ihtiyaç yoktur.

> **Beta notu:** Mevcut Intel paketi ad-hoc imzalıdır ve Apple tarafından
> notarize edilmemiştir. Bu nedenle macOS, Apple'ın uygulamanın zararlı yazılım
> içermediğini doğrulayamadığını belirten bir uyarı gösterir. Güvenli açma
> adımları aşağıdadır; Gatekeeper'ı rastgele `xattr` veya `sudo` komutlarıyla
> devre dışı bırakma.

1. GitHub sayfasındaki **Releases** bölümünden Mac'inin işlemcisine uygun `.zip`
   dosyasını indir. Mevcut beta paketi yalnızca Intel (`x86_64`) Mac'ler içindir.
2. Zip'i aç ve `SplitWire-Turkey.app` dosyasını **Applications** klasörüne taşı.
3. Uygulamayı bir kez açmayı dene ve uyarıda **Bitti / Done** seçeneğine bas.
4. Sistem Ayarları → Gizlilik ve Güvenlik bölümünü aç, aşağı kaydır ve
   SplitWire için **Yine de Aç / Open Anyway** düğmesine bas.
5. Parolan veya Touch ID ile onaylayıp son uyarıda **Aç / Open** seçeneğini kullan.
6. Uygulamada **Şifreli DNS Profilini Aç** düğmesine bas.
7. Sistem Ayarları → Genel → Aygıt Yönetimi altında profili bir kez yükle.
8. Ana ekrandaki **Discord'u Başlat** düğmesine bas.

Profil yükleme ekranında kuruluşun **SplitWire Turkey**, içeriğin yalnızca
**DNS Settings** ve DNS URL'sinin `https://cloudflare-dns.com/dns-query`
olduğunu kontrol et. Ayrıntılı ve ekran adlarıyla anlatılmış adımlar için
[kullanım kılavuzuna](docs/KULLANIM.md#ilk-kurulum) bak.

**Yine de Aç / Open Anyway** düğmesi ilk başarısız açma denemesinden sonra
yaklaşık bir saat kullanılabilir. Bu işlem yalnızca bu uygulama için istisna
oluşturur. Ayrıntılar için [Apple'ın resmi yönergesine](https://support.apple.com/guide/mac-help/open-an-app-by-overriding-security-settings-mh40617/mac)
bakabilirsin.

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

Uygulama sistem genelindeki proxy ayarlarını değiştirmez, başka uygulamaların
trafiğini yönlendirmez ve HTTPS içeriğini çözmez. **Durdur** düğmesi de yalnızca
uygulamanın kendisinin başlattığı iki yardımcı süreci kapatır.

Teknik ayrıntılar ve elle yeniden üretim adımları için
[Discord bağlantı çözümü](docs/DISCORD-BAGLANTI-COZUMU.md) belgesine bak.

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
[rehberde](docs/DISCORD-BAGLANTI-COZUMU.md#durdurma-ve-tam-geri-alma) bulunur.

## Sistem gereksinimleri

- macOS 13 Ventura veya daha yeni sürüm
- Intel Mac (mevcut beta Release paketi)
- Apple Silicon Mac (kaynak koddan derleme desteklenir; hazır beta paketi henüz
  yayımlanmadı)
- `/Applications/Discord.app` altında kurulu Discord

## Sorun giderme

- **Checking for Updates geçilmiyorsa:** DNS profilinin Sistem Ayarları'nda
  gerçekten yüklendiğini doğrula, Discord'u tamamen kapat ve uygulamadaki
  **Discord'u Başlat** düğmesini yeniden kullan.
- **1080 veya 1081 portu kullanımdaysa:** diğer proxy uygulamasını kapat. Proje
  bilinmeyen süreçleri otomatik olarak sonlandırmaz.
- **Discord bulunamadıysa:** Discord'u DMG içinden çalıştırmak yerine
  `/Applications` klasörüne taşı.

## Kaynaktan derleme

Gereksinimler: Xcode Command Line Tools ve Swift 5.9 veya daha yeni sürüm.

```bash
git clone https://github.com/karacanil/SplitWire-Turkey-macOS.git
cd SplitWire-Turkey-macOS
./build.sh
open SplitWire-Turkey.app
```

`build.sh`, Intel ve Apple Silicon için universal uygulama üretir ve yerel
geliştirme için ad-hoc imzalar. Genel dağıtıma yönelik kararlı release'ler
Developer ID ile imzalanmalı ve Apple tarafından notarize edilmelidir; ayrıntılar
[yayın kontrol listesinde](docs/RELEASE-CHECKLIST.md) yer alır.

Yalnızca Intel veya Apple Silicon paketi oluşturmak için:

```bash
TARGET_ARCH=x86_64 ./build.sh  # Intel
TARGET_ARCH=arm64 ./build.sh   # Apple Silicon
```

## Gizlilik ve güvenlik

- Telemetri ve analitik yoktur.
- Uygulama ağ içeriğini kaydetmez.
- Proxy'ler dış ağ arayüzlerinde değil, yalnızca localhost üzerinde dinler.
- Şifreli DNS profili kullanıcı tarafından açıkça kurulur ve kaldırılabilir.
- Hassas logları issue'lara yüklemeden önce kişisel bilgileri temizlemek gerekir.

Ayrıntılar: [PRIVACY.md](PRIVACY.md) ve [SECURITY.md](SECURITY.md).

## Belgeler

- [Kullanım kılavuzu](docs/KULLANIM.md)
- [Discord çözümünün teknik açıklaması](docs/DISCORD-BAGLANTI-COZUMU.md)
- [Proje yapısı](docs/PROJE-YAPISI.md)
- [Yayın kontrol listesi](docs/RELEASE-CHECKLIST.md)
- [Sürüm notları](docs/releases/)

## Kapsam

Bu fork genel amaçlı VPN, sistem proxy yöneticisi veya farklı uygulamalar için
özel başlatıcı değildir. Yalnızca yukarıda anlatılan Discord bağlantı akışını
sağlar. Upstream'deki deneysel WireGuard, düz DNS değiştirme, favori uygulamalar,
menü çubuğu preset'leri ve sistem geneli proxy özellikleri bu sürüme dahil
değildir.

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
