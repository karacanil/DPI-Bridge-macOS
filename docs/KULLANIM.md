# Kullanım kılavuzu

## İlk kurulum

1. Mac'in işlemcisine uygun Release paketini indir ve uygulamayı
   **Applications** klasörüne taşı. Intel (`x86_64`) paketi kararlıdır; Apple
   Silicon (`arm64`) paketi gerçek cihaz testi tamamlanana kadar betadır.
2. Uygulamayı bir kez açmayı dene ve zararlı yazılım doğrulama uyarısında
   **Bitti / Done** seçeneğine bas.
3. Sistem Ayarları → Gizlilik ve Güvenlik bölümünde aşağı kaydırıp SplitWire
   için **Yine de Aç / Open Anyway** düğmesine bas.
4. Parolan veya Touch ID ile onaylayıp **Aç / Open** seçeneğini kullan.
5. **Discord** ekranında **Şifreli DNS Profilini Aç** düğmesine bas.
6. Sistem Ayarları → Genel → Aygıt Yönetimi bölümünde **İndirilenler** altındaki
   **SplitWire Cloudflare Encrypted DNS** profiline çift tıkla.
7. Kuruluşun **SplitWire Turkey**, içeriğin yalnızca **DNS Settings** ve DNS
   adresinin `https://cloudflare-dns.com/dns-query` olduğunu kontrol et.
8. Profil imzasız görünebilir. Release ZIP'inin checksum'unu doğruladıysan
   **Sürdür → Yükle** adımlarıyla parola veya Touch ID kullanarak onayla.
9. Profilin **Yüklendi** bölümünde göründüğünü doğrula.
10. SplitWire'a dönüp **Discord'u Başlat** düğmesine bas.

Uygulama ByeDPI'ı ve Discord güncelleyicisinin ihtiyaç duyduğu yerel köprüyü
otomatik başlatır. İlk açılışta Discord modülleri indirildiği için işlem normalden
uzun sürebilir.

Hazır paketler ad-hoc imzalı ve notarize edilmemiştir. Bu yüzden
macOS'un gösterdiği doğrulama uyarısı beklenir. **Yine de Aç / Open Anyway**
düğmesi ilk denemeden sonra yaklaşık bir saat görünür ve yalnızca bu uygulamaya
istisna tanır. Rastgele `xattr`, `sudo` veya sertifika komutlarıyla Gatekeeper'ı
devre dışı bırakma. Ayrıntılar:
[Apple Support](https://support.apple.com/guide/mac-help/open-an-app-by-overriding-security-settings-mh40617/mac).

Şifreli DNS profili sistem genelindeki DNS sorgularını Cloudflare DNS over
HTTPS'e yönlendirir. Daha sonra Sistem Ayarları → Genel → Aygıt Yönetimi
altında profili seçip eksi (`−`) düğmesiyle kaldırabilirsin. Apple'ın ayrıntılı
profil yönergesi:
[Apple Support](https://support.apple.com/guide/mac-help/mh35561/mac).

## Günlük kullanım

- Discord'u SplitWire içindeki **Discord'u Başlat** düğmesiyle aç.
- İşin bittiğinde **Durdur** düğmesiyle ByeDPI ve güncelleyici köprüsünü kapat.

## Sorun giderme

### Klavye girdilerini alma izni isteniyor

SplitWire bu izne ihtiyaç duymaz ve klavye girdilerini okumaz. Discord,
sistem genelinde Push-to-Talk veya global tuş kısayolları kullanabilmek için
**Input Monitoring / Giriş İzleme** izni isteyebilir. Bu özellikleri
kullanmıyorsan isteği reddedebilirsin.

İzin ekranında SplitWire adı görünüyorsa eski Beta 2 kullanılıyor olabilir.
Güncel 1.1.0 paketine yükselt ve Sistem Ayarları → Gizlilik ve Güvenlik → Giriş
İzleme altından eski SplitWire iznini kapat. Güncel sürüm Discord'u Launch
Services üzerinden başlattığı için Discord'a ait izin SplitWire adına
gösterilmez.

### Checking for Updates ekranı geçilmiyor

1. Şifreli DNS profilinin kurulu olduğunu kontrol et.
2. Discord'u tamamen kapat.
3. SplitWire'da **Durdur** düğmesine bas.
4. **Discord'u Başlat** düğmesine tekrar bas.

### Port kullanımda uyarısı

Başka bir proxy uygulaması `1080` veya `1081` portunu kullanıyor olabilir.
İlgili uygulamayı kapat ve tekrar dene. Kaynağını bilmediğin süreçleri zorla
kapatma.

### Uygulama açılmıyor

Önce uygulamayı açmayı dene; ardından Sistem Ayarları → Gizlilik ve Güvenlik
altındaki **Yine de Aç / Open Anyway** düğmesini kullan. Düğme görünmiyorsa
uygulamayı yeniden açmayı dene ve bu ekrana bir saat içinde dön. Release'in
imza/notarizasyon bilgisini release notundan kontrol et.

## Kaldırma

1. SplitWire'da **Durdur** düğmesine bas ve uygulamadan çık.
2. Sistem Ayarları → Genel → Aygıt Yönetimi bölümünde
   **SplitWire Cloudflare Encrypted DNS** profilini kaldır.
3. Applications klasöründeki uygulamayı Çöp Sepeti'ne taşı.

Kaynak kod scriptlerini kullanan geliştiriciler tam geri dönüş için şunu
çalıştırabilir:

```bash
./scripts/restore-discord-network.sh
```

Daha ayrıntılı teknik bilgi için
[DISCORD-BAGLANTI-COZUMU.md](DISCORD-BAGLANTI-COZUMU.md) belgesine bak.
