#!/bin/zsh

set -eu

REPO_ROOT=${0:A:h:h}
cd "$REPO_ROOT"
EXPECTED_ARCH=${EXPECTED_ARCH:-universal}

fail() {
    print -u2 "HATA: $*"
    exit 1
}

print "[1/6] Kişisel yol ve yaygın secret kalıpları taranıyor..."
CURRENT_USER=$(id -un)
PATTERN="/Users/|BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|api[_-]?key[[:space:]]*[:=]|client[_-]?secret[[:space:]]*[:=]|access[_-]?token[[:space:]]*[:=]|authorization:[[:space:]]*bearer"
if rg -n -i --hidden -g '!.git/**' -g '!.build/**' -g '!byedpi/**' \
    -g '!scripts/preflight-release.sh' -e "$PATTERN" .; then
    fail "Kişisel yol veya secret adayı bulundu."
fi
if [[ -n "$CURRENT_USER" ]] && rg -n -i --hidden -g '!.git/**' -g '!.build/**' -e "$CURRENT_USER" .; then
    fail "Yerel kullanıcı adı repo içinde bulundu."
fi

print "[2/6] Hassas dosya türleri kontrol ediliyor..."
if git ls-files | rg -q '(^|/)(\.env|settings\.txt)$|\.(p12|pem|key|mobileprovision)$'; then
    fail "Commit edilmemesi gereken yerel/hassas dosya bulundu."
fi

print "[3/6] Script ve profil biçimleri doğrulanıyor..."
bash -n build.sh
for script in scripts/launch-discord.sh scripts/restore-discord-network.sh; do
    if ! SYNTAX_OUTPUT=$(zsh -n "$script" 2>&1); then
        print -u2 -- "$SYNTAX_OUTPUT"
        fail "$script sözdizimi geçersiz."
    fi
done
plutil -lint DPI-Bridge-Cloudflare-Encrypted-DNS.mobileconfig >/dev/null

print "[4/6] Universal ciadpi doğrulanıyor..."
ARCHS=$(lipo -archs Sources/DPIBridge/Resources/bin/ciadpi)
[[ "$ARCHS" == *"x86_64"* && "$ARCHS" == *"arm64"* ]] \
    || fail "ciadpi universal değil: $ARCHS"

print "[5/6] Yerel proxy güvenlik sınırları kontrol ediliyor..."
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

print "[6/6] Git diff biçimi kontrol ediliyor..."
git diff --check

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
fi

print "Ön yayın statik kontrolleri başarılı."
