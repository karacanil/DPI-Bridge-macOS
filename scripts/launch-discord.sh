#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
REPO_ROOT=${SCRIPT_DIR:h}
PROFILE_PATH="$REPO_ROOT/SplitWire-Cloudflare-Encrypted-DNS.mobileconfig"
DISCORD_BIN="/Applications/Discord.app/Contents/MacOS/Discord"
CIADPI_PID_FILE="/tmp/splitwire-ciadpi.pid"
BRIDGE_PID_FILE="/tmp/splitwire-discord-http-proxy.pid"
CIADPI_LOG="/tmp/splitwire-ciadpi.log"
BRIDGE_LOG="/tmp/splitwire-discord-http-proxy.log"
DISCORD_LOG="/tmp/splitwire-discord-launch.log"

die() {
    print -u2 "Hata: $*"
    exit 1
}

port_is_listening() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

find_ciadpi() {
    local candidates=(
        "$REPO_ROOT/SplitWire-Turkey.app/Contents/Resources/bin/ciadpi"
        "$REPO_ROOT/Sources/SplitWireTurkey/Resources/bin/ciadpi"
        "$REPO_ROOT/byedpi/ciadpi"
    )
    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -x "$candidate" ]]; then
            print -r -- "$candidate"
            return 0
        fi
    done
    return 1
}

find_proxy_bridge() {
    local candidates=(
        "$REPO_ROOT/SplitWire-Turkey.app/Contents/Resources/bin/discord-http-proxy"
        "$REPO_ROOT/.build/universal/release/discord-http-proxy"
        "$REPO_ROOT/.build/release/discord-http-proxy"
        "$REPO_ROOT/.build/debug/discord-http-proxy"
    )
    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -x "$candidate" ]]; then
            print -r -- "$candidate"
            return 0
        fi
    done
    return 1
}

stop_owned_process() {
    local pid_file=$1
    local expected=$2
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(<"$pid_file")
        local command
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
        fi
        rm -f "$pid_file"
    fi
}

if [[ "${1:-}" == "--stop" ]]; then
    stop_owned_process "$BRIDGE_PID_FILE" "discord-http-proxy"
    stop_owned_process "$CIADPI_PID_FILE" "ciadpi"
    print "SplitWire yardımcı süreçleri durduruldu."
    exit 0
fi

[[ -x "$DISCORD_BIN" ]] || die "Discord bulunamadı: $DISCORD_BIN"
[[ -f "$PROFILE_PATH" ]] || die "Şifreli DNS profili bulunamadı: $PROFILE_PATH"

if ! profiles list -type configuration 2>&1 | grep -q "com.splitwire.cloudflare-doh"; then
    print "Cloudflare şifreli DNS profili henüz kurulu değil."
    open "$PROFILE_PATH"
    open "x-apple.systempreferences:com.apple.preferences.configurationprofiles"
    print "Aygıt Yönetimi ekranında profili yükledikten sonra bu scripti yeniden çalıştır."
    exit 2
fi

if ! port_is_listening 1080; then
    CIADPI_BIN=$(find_ciadpi) || die "ciadpi çalıştırılabilir dosyası bulunamadı. Önce uygulamayı derle."
    nohup "$CIADPI_BIN" --ip 127.0.0.1 \
        --disorder 1 --auto=torst --tlsrec 1+s >"$CIADPI_LOG" 2>&1 &
    print $! >"$CIADPI_PID_FILE"
    sleep 1
fi
port_is_listening 1080 || die "ByeDPI 1080 portunu açamadı. Log: $CIADPI_LOG"

if ! port_is_listening 1081; then
    BRIDGE_BIN=$(find_proxy_bridge) || die "Derlenmiş HTTP→SOCKS köprüsü bulunamadı. Önce ./build.sh çalıştır."
    nohup "$BRIDGE_BIN" >"$BRIDGE_LOG" 2>&1 &
    print $! >"$BRIDGE_PID_FILE"
    sleep 1
fi
port_is_listening 1081 || die "HTTP→SOCKS köprüsü 1081 portunu açamadı. Log: $BRIDGE_LOG"

curl --proxy http://127.0.0.1:1081 --connect-timeout 15 --max-time 30 \
    --silent --show-error --output /dev/null https://updates.discord.com/ \
    || die "Discord güncelleme sunucusuna proxy üzerinden erişilemiyor."

osascript -e 'tell application "Discord" to quit' >/dev/null 2>&1 || true
sleep 1

nohup env \
    HTTPS_PROXY=http://127.0.0.1:1081 \
    HTTP_PROXY=http://127.0.0.1:1081 \
    ALL_PROXY=http://127.0.0.1:1081 \
    https_proxy=http://127.0.0.1:1081 \
    http_proxy=http://127.0.0.1:1081 \
    all_proxy=http://127.0.0.1:1081 \
    NO_PROXY=127.0.0.1,localhost \
    no_proxy=127.0.0.1,localhost \
    "$DISCORD_BIN" \
    --proxy-server=socks5://127.0.0.1:1080 \
    --disable-quic >"$DISCORD_LOG" 2>&1 &

print "Discord başlatıldı."
print "ByeDPI: SOCKS5 127.0.0.1:1080"
print "Güncelleyici köprüsü: HTTP CONNECT 127.0.0.1:1081"
print "Başlatma logu: $DISCORD_LOG"
print "Yardımcı süreçleri kapatmak için: $0 --stop"
