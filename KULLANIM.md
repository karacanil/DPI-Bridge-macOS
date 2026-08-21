# Kullanım kılavuzu

## İlk kurulum

1. Release paketini indir ve uygulamayı **Applications** klasörüne taşı.
2. Uygulamaya sağ tıklayıp **Aç** seçeneğini kullan.
3. **Discord** ekranında **Şifreli DNS Profilini Aç** düğmesine bas.
4. Sistem Ayarları → Genel → Aygıt Yönetimi bölümünde profili yükle.
5. **Discord'u Başlat** düğmesine bas.

Uygulama ByeDPI'ı ve Discord güncelleyicisinin ihtiyaç duyduğu yerel köprüyü
otomatik başlatır. İlk açılışta Discord modülleri indirildiği için işlem normalden
uzun sürebilir.

## Günlük kullanım

- Discord'u SplitWire içindeki **Discord'u Başlat** düğmesiyle aç.
- İşin bittiğinde **Durdur** düğmesiyle ByeDPI ve güncelleyici köprüsünü kapat.

## Sorun giderme

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

Uygulamaya Finder'da sağ tıklayıp **Aç** seçeneğini kullan. Resmî release'in
imza/notarizasyon bilgisi release notunda yayınlanmalıdır. İnternetten bulunan
rastgele `xattr`, `sudo` veya sertifika komutlarını çalıştırma.

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
