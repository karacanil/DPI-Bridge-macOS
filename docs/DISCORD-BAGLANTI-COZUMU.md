# DPI Bridge ile Discord bağlantı çözümü

Bu belge, macOS üzerinde Discord'un **Checking for Updates** ekranında kalmasının
nedenini, uygulanan çözümü ve çözümün temiz bir sistemde nasıl yeniden
üretileceğini açıklar.

## Kısa özet

Sorun iki ayrı katmandan oluşuyordu:

1. İnternet sağlayıcısının DNS'i `discord.com` ve `updates.discord.com` gibi
   alan adlarını gerçek Discord adresleri yerine `195.175.254.2` adresine
   yönlendiriyordu.
2. Discord'un Electron sürecinden ayrı çalışan güncelleyicisi
   `--proxy-server=socks5://127.0.0.1:1080` parametresini kullanmıyor. Bu nedenle
   ana Discord uygulaması ByeDPI üzerinden çalışabilse bile güncelleyici doğrudan
   bağlanmaya çalışıp açılış ekranında kalıyordu.

Çözüm üç parçadan oluşur:

```text
Discord ana uygulaması ──SOCKS5──────────────▶ ByeDPI :1080 ──▶ İnternet
Discord güncelleyicisi ──HTTP CONNECT :1081──▶ HTTP→SOCKS köprüsü
                                                  │
                                                  └──SOCKS5──▶ ByeDPI :1080

Alan adı çözümleme ──DNS over HTTPS──▶ Cloudflare
```

## Repodaki parçalar

- `DPI-Bridge-Cloudflare-Encrypted-DNS.mobileconfig`: macOS'a Cloudflare DNS over
  HTTPS yapılandırması ekler. Profil imzasızdır, kullanıcı tarafından
  kurulabilir ve kaldırılabilir.
- `Sources/DiscordHTTPProxy/main.c`: yalnızca `127.0.0.1:1081` üzerinde
  dinleyen, Discord güncelleyicisinin HTTP `CONNECT` isteklerini ByeDPI'ın
  SOCKS5 portuna aktaran küçük yerel yardımcı. Discord dışındaki alan adlarını
  reddeder.
- `scripts/launch-discord.sh`: profili ve gerekli dosyaları kontrol eder,
  ByeDPI/köprüyü başlatır, bağlantıyı sınar ve Discord'u doğru ortam
  değişkenleriyle açar.

## Gereksinimler

- macOS 13 veya daha yeni sürüm
- `/Applications/Discord.app` altında kurulu Discord
- Derlenmiş `DPI-Bridge.app`; script ile çalışılacaksa ayrıca repoda
  derlenmiş `discord-http-proxy` çıktısı
- Profil kurulumunu onaylayabilecek bir macOS kullanıcı hesabı

## İlk kurulum

### 1. Şifreli DNS profilini kur

Finder'da `DPI-Bridge-Cloudflare-Encrypted-DNS.mobileconfig` dosyasını aç.
Ardından:

1. **Sistem Ayarları → Genel → Aygıt Yönetimi** bölümüne git.
2. **DPI Bridge Cloudflare Encrypted DNS** profilini seç.
3. **Yükle** düğmesine bas ve macOS parolanla onayla.

Profil sayfası doğrudan açılmazsa Terminal'de şu komut kullanılabilir:

```bash
open "x-apple.systempreferences:com.apple.preferences.configurationprofiles"
```

Kurulumu doğrula:

```bash
profiles list -type configuration
dscacheutil -q host -a name discord.com
```

Çıktıda `com.splitwire.cloudflare-doh` görülmeli. `discord.com` geçerli genel
IP adreslerine çözülmeli; engelleme yönlendirmesinde görülen `195.175.254.2`
adresine çözülmemeli.

### 2. Tek komutla Discord'u başlat

Repo kökünde:

```bash
chmod +x scripts/launch-discord.sh
./scripts/launch-discord.sh
```

Script şu işlemleri yapar:

1. Şifreli DNS profilinin kurulu olduğunu doğrular.
2. Gerekirse ByeDPI'ı `127.0.0.1:1080` üzerinde `Disorder` yöntemiyle başlatır.
3. HTTP→SOCKS köprüsünü `127.0.0.1:1081` üzerinde başlatır.
4. `updates.discord.com` bağlantısını köprü üzerinden sınar.
5. Açık Discord'u kapatıp yeniden başlatır.
6. Electron trafiğine SOCKS5, güncelleyiciye standart HTTP proxy verir.

İlk başarılı çalışmada Discord eksik yerel modülleri indirebilir. Güncelleme
ekranı tamamlandıktan sonra ana pencere açılır.

## Elle yeniden üretme

Otomatik script kullanılmadan aynı akış aşağıdaki komutlarla kurulabilir.

ByeDPI:

```bash
./DPI-Bridge.app/Contents/Resources/bin/ciadpi \
  --ip 127.0.0.1 \
  --disorder 1 --auto=torst --tlsrec 1+s
```

Ayrı bir Terminal penceresinde derlenmiş HTTP→SOCKS köprüsü:

```bash
./DPI-Bridge.app/Contents/Resources/bin/discord-http-proxy
```

Bağlantı testi:

```bash
curl --proxy http://127.0.0.1:1081 \
  --connect-timeout 15 --max-time 30 \
  -o /dev/null -w '%{http_code}\n' \
  https://updates.discord.com/
```

Burada `404` geçerli bir başarı sonucudur: sunucuya TLS üzerinden ulaşıldığını,
yalnızca `/` yolunda içerik bulunmadığını gösterir.

Discord'u başlat:

```bash
env \
  HTTPS_PROXY=http://127.0.0.1:1081 \
  HTTP_PROXY=http://127.0.0.1:1081 \
  ALL_PROXY=http://127.0.0.1:1081 \
  /Applications/Discord.app/Contents/MacOS/Discord \
  --proxy-server=socks5://127.0.0.1:1080 \
  --disable-quic
```

## Doğrulama

Portlar:

```bash
lsof -nP -iTCP:1080 -sTCP:LISTEN
lsof -nP -iTCP:1081 -sTCP:LISTEN
```

Discord API:

```bash
curl --proxy socks5h://127.0.0.1:1080 \
  https://discord.com/api/v10/gateway
```

Başarılı yanıtta WebSocket ağ geçidi adresini içeren JSON görülür.

Discord güncelleyici logu:

```bash
tail -f "$HOME/Library/Application Support/discord/logs/Discord_updater_rCURRENT.log"
```

Başarılı akışta modüller indirilir, kurulur ve açılış ekranı `launching`
aşamasına geçer.

## Durdurma ve tam geri alma

### Yalnızca çalışan yardımcı süreçleri durdurma

Scriptin başlattığı ByeDPI ve köprü süreçlerini kapat:

```bash
./scripts/launch-discord.sh --stop
```

Bu komut DNS profilini veya Discord ayar dosyasını değiştirmez. Daha sonra aynı
çözümü kullanmak istiyorsan önerilen seçenek budur.

### Bütün değişiklikleri geri alma

Repo kökünde aşağıdaki scripti çalıştır:

```bash
./scripts/restore-discord-network.sh
```

Geri yükleme scripti:

1. Scriptin başlattığı ByeDPI ve HTTP→SOCKS süreçlerini kapatır.
2. `1080` ve `1081` portlarında bu projeye ait kalmış süreçleri güvenli biçimde
   kapatır; başka uygulamalara ait süreçlere dokunmaz.
3. Önceki denemelerde eklenmişse Discord'un `settings.json` dosyasından yalnızca
   `SKIP_HOST_UPDATE` ve `SKIP_MODULE_UPDATE` anahtarlarını kaldırır. Discord'un
   sonradan eklediği diğer ayarları korur.
4. Yalnızca `127.0.0.1:1080` değerine ayarlıysa Wi-Fi sistem SOCKS proxy'sini
   kapatır. Başka bir proxy yapılandırmasını değiştirmez.
5. Şifreli DNS profili kuruluysa macOS Aygıt Yönetimi ekranını açar.

Şifreli DNS profilini kaldırmak için:

1. **Sistem Ayarları → Genel → Aygıt Yönetimi** bölümünü aç.
2. **DPI Bridge Cloudflare Encrypted DNS** profilini seç.
3. Eksi (`−`) düğmesiyle profili kaldır.

macOS profil kaldırma işlemi için kullanıcı onayı istediğinden bu son tıklama
bilerek otomatikleştirilmemiştir.

Profil kaldırıldıktan sonra DNS önbelleğini temizlemek isteğe bağlıdır:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Tam geri dönüşü doğrula:

```bash
# DPI Bridge profili listelenmemeli
profiles list -type configuration

# İki yardımcı port da boş olmalı
lsof -nP -iTCP:1080 -sTCP:LISTEN
lsof -nP -iTCP:1081 -sTCP:LISTEN

# Sistem SOCKS proxy kapalı olmalı
networksetup -getsocksfirewallproxy "Wi-Fi"

# İki eski güncelleme anahtarı bulunmamalı (çıktı vermemeli)
grep -E 'SKIP_HOST_UPDATE|SKIP_MODULE_UPDATE' \
  "$HOME/Library/Application Support/discord/settings.json" || true
```

Son komut çıktı vermemelidir. `networksetup` çıktısında `Enabled: No`
görülmelidir. `lsof` komutlarının çıktı vermemesi portların boş olduğunu
gösterir.

Bu çözüm sistem SOCKS proxy'sini açık bırakmaz. Sistem SOCKS proxy ile şifreli
DNS'in birlikte kullanılması, DNS sunucusunun kendisini çözümleyemediği bir
döngü oluşturabilir.

## Sorun giderme

### DNS hâlâ `195.175.254.2` döndürüyor

Profilin kurulu olduğunu kontrol et, Wi-Fi'yi kapatıp aç ve DNS önbelleğini
temizle:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### 1080 portu açılmıyor

```bash
lsof -nP -iTCP:1080 -sTCP:LISTEN
tail -100 /tmp/dpi-bridge-ciadpi.log
```

Portu başka bir program kullanıyorsa önce o programı güvenli biçimde kapat.

### Güncelleyici `unsuccessful tunnel` diyor

DNS çözümlemesini ve köprüyü kontrol et:

```bash
dscacheutil -q host -a name stable.dl2.discordapp.net
tail -100 /tmp/dpi-bridge-discord-http-proxy.log
```

Ardından `scripts/launch-discord.sh` komutunu tekrar çalıştır.

### `settings.json` neden tek başına yetmiyor?

Eski Discord güncelleyicisi `SKIP_HOST_UPDATE` ve `SKIP_MODULE_UPDATE`
anahtarlarını kullanıyordu. Mevcut yeni güncelleyici başlatma manifestini yine
kontrol ettiği için bu dosya tek başına **Checking for Updates** sorununu
çözmüyor. HTTP→SOCKS köprüsü bu nedenle gereklidir.
