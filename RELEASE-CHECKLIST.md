# Yayın kontrol listesi

Bu liste her halka açık sürümden önce tamamlanmalıdır.

## Kaynak ve gizlilik

- [ ] `./scripts/preflight-release.sh` başarıyla tamamlandı.
- [ ] `git status --short` yalnızca sürüme girecek dosyaları gösteriyor.
- [ ] `.env`, sertifika, özel anahtar, token, kişisel yol ve yerel log yok.
- [ ] Git geçmişi secret scanner ile kontrol edildi.
- [ ] Üçüncü taraf lisans ve atıfları korundu.
- [ ] README'deki fork/release bağlantıları doğru repoyu gösteriyor.

## Derleme

- [ ] Temiz checkout üzerinde `./build.sh` çalıştı.
- [ ] Ana uygulama, `ciadpi` ve `discord-http-proxy` hem `arm64` hem `x86_64`.
- [ ] Uygulama içindeki DNS profili `plutil -lint` kontrolünden geçti.
- [ ] Uygulama Developer ID Application sertifikasıyla imzalandı.
- [ ] Apple notarizasyonu tamamlandı ve ticket uygulamaya stapled edildi.
- [ ] Zip veya DMG için SHA-256 özeti üretildi.

Örnek imza/notarizasyon akışı (kimlik ve profil adlarını kendi CI secret'larınla
sağla; repoya yazma):

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: …" SplitWire-Turkey.app

ditto -c -k --keepParent SplitWire-Turkey.app SplitWire-Turkey.zip
xcrun notarytool submit SplitWire-Turkey.zip \
  --keychain-profile "NOTARY_PROFILE" --wait
xcrun stapler staple SplitWire-Turkey.app
shasum -a 256 SplitWire-Turkey.zip
```

## Temiz Mac testi

- [ ] Daha önce SplitWire kurulmamış Intel Mac'te test edildi.
- [ ] Daha önce SplitWire kurulmamış Apple Silicon Mac'te test edildi.
- [ ] Kullanıcı geliştirici aracı veya Python kurmadan uygulamayı açabildi.
- [ ] DNS profili uygulama içinden açıldı ve kaldırılabildi.
- [ ] Discord ilk kurulum/güncelleme ekranını geçti.
- [ ] Discord metin, WebSocket ve ses bağlantısı çalıştı.
- [ ] ByeDPI durdurulunca `1080` ve `1081` portları kapandı.
- [ ] Tam kaldırma sonrası DNS ve proxy ayarları eski haline döndü.

## Release içeriği

- [ ] Sürüm numarası Info.plist ve About ekranında güncel.
- [ ] Değişiklik notları teknik olmayan kısa bir özet içeriyor.
- [ ] Bilinen kısıtlar açıkça yazıldı.
- [ ] İmzalı/notarize artifact ve SHA-256 özeti eklendi.
- [ ] Güvenlik bildirim kanalı etkinleştirildi.
