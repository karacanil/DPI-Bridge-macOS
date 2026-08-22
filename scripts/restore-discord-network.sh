#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
SETTINGS_PATH="$HOME/Library/Application Support/discord/settings.json"

stop_matching_listener() {
    local port=$1
    local expected=$2
    local pid command
    for pid in $(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true); do
        command=$(ps -p "$pid" -o command= 2>/dev/null || true)
        if [[ "$command" == *"$expected"* ]]; then
            kill "$pid" 2>/dev/null || true
            for _ in {1..10}; do
                kill -0 "$pid" 2>/dev/null || break
                sleep 0.1
            done
            command=$(ps -p "$pid" -o command= 2>/dev/null || true)
            if [[ "$command" == *"$expected"* ]]; then
                kill -9 "$pid" 2>/dev/null || true
            fi
        else
            print "Uyarı: $port portundaki $pid süreci SplitWire'a ait görünmüyor; kapatılmadı."
        fi
    done
}

"$SCRIPT_DIR/launch-discord.sh" --stop
stop_matching_listener 1081 "discord-http-proxy"
stop_matching_listener 1080 "ciadpi"

if [[ -f "$SETTINGS_PATH" ]]; then
    osascript -l JavaScript -e '
        ObjC.import("Foundation");
        function run(argv) {
            const path = argv[0];
            const text = $.NSString.stringWithContentsOfFileEncodingError(
                path, $.NSUTF8StringEncoding, null
            ).js;
            const settings = JSON.parse(text);
            delete settings.SKIP_HOST_UPDATE;
            delete settings.SKIP_MODULE_UPDATE;
            const output = $(JSON.stringify(settings, null, 2) + "\n");
            if (!output.writeToFileAtomicallyEncodingError(
                path, true, $.NSUTF8StringEncoding, null
            )) throw new Error("settings.json yazılamadı");
        }
    ' "$SETTINGS_PATH"
    print "Discord settings.json içindeki eski SplitWire güncelleme anahtarları kaldırıldı."
fi

SOCKS_STATUS=$(networksetup -getsocksfirewallproxy "Wi-Fi" 2>/dev/null || true)
if [[ "$SOCKS_STATUS" == *"Enabled: Yes"* &&
      "$SOCKS_STATUS" == *"Server: 127.0.0.1"* &&
      "$SOCKS_STATUS" == *"Port: 1080"* ]]; then
    osascript -e \
        'do shell script "networksetup -setsocksfirewallproxystate '\''Wi-Fi'\'' off" with administrator privileges'
    print "SplitWire'a ait Wi-Fi sistem SOCKS proxy ayarı kapatıldı."
else
    print "Wi-Fi sistem SOCKS ayarı değiştirilmedi (SplitWire 127.0.0.1:1080 ayarı etkin değil)."
fi

if profiles list -type configuration 2>&1 | grep -q "com.splitwire.cloudflare-doh"; then
    open "x-apple.systempreferences:com.apple.preferences.configurationprofiles"
    print ""
    print "Son kullanıcı onayı gerekiyor:"
    print "Aygıt Yönetimi'nde 'SplitWire Cloudflare Encrypted DNS' profilini seçip eksi (−) ile kaldır."
else
    print "SplitWire Cloudflare DNS profili kurulu görünmüyor."
fi

print ""
print "Profil kaldırıldıktan sonra isteğe bağlı DNS önbelleği temizliği:"
print "  sudo dscacheutil -flushcache"
print "  sudo killall -HUP mDNSResponder"
print ""
print "Çalışma zamanı ayarlarının geri alınması tamamlandı."
