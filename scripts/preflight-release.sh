#!/bin/zsh

set -eu

REPO_ROOT=${0:A:h:h}
cd "$REPO_ROOT"
EXPECTED_ARCH=${EXPECTED_ARCH:-universal}

fail() {
    print -u2 "HATA: $*"
    exit 1
}

print "[1/8] Kişisel yol ve yaygın secret kalıpları taranıyor..."
CURRENT_USER=$(id -un)
PATTERN="/Users/[[:alnum:]_.-]+/|BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|api[_-]?key[[:space:]]*[:=]|client[_-]?secret[[:space:]]*[:=]|access[_-]?token[[:space:]]*[:=]|authorization:[[:space:]]*bearer"
if rg -n -i --hidden -g '!.git/**' -g '!.build/**' -g '!*.app/**' -g '!*.zip' \
    -g '!scripts/preflight-release.sh' -g '!scripts/audit-public-readiness.sh' \
    -e "$PATTERN" .; then
    fail "Kişisel yol veya secret adayı bulundu."
fi
if [[ -n "$CURRENT_USER" ]] && rg -n -i --hidden -g '!.git/**' -g '!.build/**' \
    -g '!*.app/**' -g '!*.zip' -e "$CURRENT_USER" .; then
    fail "Yerel kullanıcı adı repo içinde bulundu."
fi

print "[2/8] Hassas dosya türleri kontrol ediliyor..."
if git ls-files | rg -q '(^|/)(\.env|settings\.txt)$|\.(p12|pem|key|mobileprovision)$'; then
    fail "Commit edilmemesi gereken yerel/hassas dosya bulundu."
fi

print "[3/8] Script ve profil biçimleri doğrulanıyor..."
bash -n build.sh
for script in scripts/*.sh; do
    if ! SYNTAX_OUTPUT=$(zsh -n "$script" 2>&1); then
        print -u2 -- "$SYNTAX_OUTPUT"
        fail "$script sözdizimi geçersiz."
    fi
done
plutil -lint DPI-Bridge-Cloudflare-Encrypted-DNS.mobileconfig >/dev/null

print "[4/8] ByeDPI provenance ve kaynak derlemesi doğrulanıyor..."
[[ "$(<byedpi/UPSTREAM_COMMIT)" == "ba532298de7b28cfe854aea83d061369d13ca290" ]] \
    || fail "Sabit ByeDPI commit dosyası eksik veya beklenmeyen değerde."
rg -q 'ba532298de7b28cfe854aea83d061369d13ca290' THIRD_PARTY.md \
    || fail "Sabit ByeDPI commit'i THIRD_PARTY.md içinde belgelenmemiş."
[[ -f byedpi/LICENSE && -f scripts/build-ciadpi.sh ]] \
    || fail "ByeDPI lisansı veya kaynak derleme scripti eksik."
if git ls-files --error-unmatch Sources/DPIBridge/Resources/bin/ciadpi >/dev/null 2>&1; then
    fail "Opaque ciadpi binary repo içinde takip edilmemeli."
fi

print "[5/8] Yerel proxy güvenlik sınırları kontrol ediliyor..."
rg -q 'inet_pton\(AF_INET, "127\.0\.0\.1"' Sources/DiscordHTTPProxy/main.c \
    || fail "Proxy localhost'a sabitlenmemiş."
rg -q 'parsed_port != 443' Sources/DiscordHTTPProxy/main.c \
    || fail "Proxy HTTPS portuyla sınırlandırılmamış."
rg -q '"--ip", "127\.0\.0\.1"' Sources/DPIBridge/Services/ByeDPIService.swift \
    || fail "Uygulama ByeDPI'ı localhost'a sabitlemiyor."
rg -q -- '--ip 127\.0\.0\.1' scripts/launch-discord.sh \
    || fail "Başlatma scripti ByeDPI'ı localhost'a sabitlemiyor."
rg -q 'fileURLWithPath: "/usr/bin/open"' Sources/DPIBridge/Services/ByeDPIService.swift \
    || fail "Discord Launch Services üzerinden başlatılmıyor."
rg -q '"--env"' Sources/DPIBridge/Services/ByeDPIService.swift \
    || fail "Discord proxy ortamı Launch Services'e aktarılmıyor."

print "[6/8] Birinci taraf Git diff biçimi kontrol ediliyor..."
# Vendored ByeDPI snapshot'ı upstream ile byte-for-byte uyumlu tutulur; upstream
# whitespace stili yerel format kontrolünün kapsamı dışındadır.
git diff --check -- . ':!byedpi/**'

if [[ -d DPI-Bridge.app ]]; then
    for executable in \
        DPI-Bridge.app/Contents/MacOS/DPI-Bridge \
        DPI-Bridge.app/Contents/Resources/bin/ciadpi \
        DPI-Bridge.app/Contents/Resources/bin/discord-http-proxy; do
        ARCHS=$(lipo -archs "$executable")
        if [[ "$EXPECTED_ARCH" == "universal" ]]; then
            [[ "$ARCHS" == *"x86_64"* && "$ARCHS" == *"arm64"* ]] \
                || fail "$executable universal değil: $ARCHS"
        else
            [[ "$ARCHS" == "$EXPECTED_ARCH" ]] \
                || fail "$executable beklenen $EXPECTED_ARCH mimarisinde değil: $ARCHS"
        fi
    done
    codesign --verify --deep --strict DPI-Bridge.app \
        || fail "Uygulama imzası geçersiz."

    print "[7/8] Uygulama binary'lerinde yerel build izi aranıyor..."
    for executable in \
        DPI-Bridge.app/Contents/MacOS/DPI-Bridge \
        DPI-Bridge.app/Contents/Resources/bin/ciadpi \
        DPI-Bridge.app/Contents/Resources/bin/discord-http-proxy; do
        if rg -a -q '/Users/|/home/' "$executable"; then
            fail "$executable yerel build yolu içeriyor."
        fi
    done
    if [[ -n "$(xattr -r DPI-Bridge.app 2>/dev/null)" ]]; then
        fail "Uygulama paketi extended attribute içeriyor."
    fi
else
    print "[7/8] Uygulama paketi yok; binary mahremiyet kontrolü atlandı."
fi

print "[8/8] Release ZIP kontrol ediliyor..."
if [[ -n "${RELEASE_ARCHIVE:-}" ]]; then
    [[ -f "$RELEASE_ARCHIVE" ]] || fail "Release ZIP bulunamadı: $RELEASE_ARCHIVE"
    unzip -t "$RELEASE_ARCHIVE" >/dev/null || fail "Release ZIP bozuk."
    if unzip -Z1 "$RELEASE_ARCHIVE" | rg -q '(^|/)__MACOSX/|(^|/)\._'; then
        fail "Release ZIP AppleDouble/resource-fork girdisi içeriyor."
    fi
    if unzip -p "$RELEASE_ARCHIVE" | rg -a -q '/Users/|/home/'; then
        fail "Release ZIP yerel kullanıcı yolu içeriyor."
    fi
else
    print "RELEASE_ARCHIVE ayarlanmadı; ZIP kontrolü atlandı."
fi

print "Ön yayın statik kontrolleri başarılı."
