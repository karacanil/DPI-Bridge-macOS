# Yayın kontrol listesi

Bu liste her halka açık sürümden önce tamamlanmalıdır.

## Kaynak ve gizlilik

- [ ] `./scripts/preflight-release.sh` başarıyla tamamlandı.
- [ ] `./scripts/audit-public-readiness.sh` başarıyla tamamlandı.
- [ ] `git status --short` yalnızca sürüme girecek dosyaları gösteriyor.
- [ ] `.env`, sertifika, özel anahtar, token, kişisel yol ve yerel log yok.
- [ ] Git geçmişi secret scanner ile kontrol edildi.
- [ ] Üçüncü taraf lisans ve atıfları korundu.
- [ ] README'deki fork/release bağlantıları doğru repoyu gösteriyor.

## Derleme

- [ ] Temiz checkout üzerinde `./build.sh` çalıştı.
- [ ] Universal pakette üç binary de `arm64` + `x86_64`; mimariye özel pakette
      üçü de release etiketinde belirtilen tek mimariyi içeriyor.
- [ ] `ciadpi`, [THIRD_PARTY.md](../THIRD_PARTY.md) içinde sabitlenen upstream
      commit'in vendored kaynaklarından yeniden üretildi.
- [ ] Uygulama içindeki DNS profili `plutil -lint` kontrolünden geçti.
- [ ] Uygulama Developer ID Application sertifikasıyla imzalandı.
- [ ] Apple notarizasyonu tamamlandı ve ticket uygulamaya stapled edildi.
- [ ] Zip veya DMG için SHA-256 özeti üretildi.
- [ ] ZIP içinde AppleDouble (`._*`, `__MACOSX`) girdisi ve binary'lerde yerel
      `/Users/` veya `/home/` build yolu yok.

Örnek imza/notarizasyon akışı (kimlik ve profil adlarını kendi CI secret'larınla
sağla; repoya yazma):

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: …" DPI-Bridge.app

ditto -c -k --keepParent DPI-Bridge.app DPI-Bridge.zip
xcrun notarytool submit DPI-Bridge.zip \
  --keychain-profile "NOTARY_PROFILE" --wait
xcrun stapler staple DPI-Bridge.app
shasum -a 256 DPI-Bridge.zip
```

## Temiz Mac testi

- [ ] Daha önce DPI Bridge kurulmamış Intel Mac'te test edildi.
- [ ] Daha önce DPI Bridge kurulmamış Apple Silicon Mac'te test edildi.
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
