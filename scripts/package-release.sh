#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
REPO_ROOT=${SCRIPT_DIR:h}
cd "$REPO_ROOT"

archive_path=${1:-}
[[ -n "$archive_path" ]] || {
    print -u2 "Kullanım: $0 <çıktı.zip>"
    exit 1
}
[[ -d DPI-Bridge.app ]] || {
    print -u2 "HATA: DPI-Bridge.app bulunamadı. Önce ./build.sh çalıştır."
    exit 1
}

case "$archive_path" in
    /*) ;;
    *) archive_path="$REPO_ROOT/$archive_path" ;;
esac

COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent DPI-Bridge.app "$archive_path"
unzip -t "$archive_path" >/dev/null

if unzip -Z1 "$archive_path" | rg -q '(^|/)__MACOSX/|(^|/)\._'; then
    print -u2 "HATA: ZIP AppleDouble/resource-fork girdisi içeriyor."
    exit 1
fi

if unzip -p "$archive_path" | rg -a -q '/Users/|/home/'; then
    print -u2 "HATA: ZIP yerel kullanıcı yolu içeriyor."
    exit 1
fi

print "Paket hazır: $archive_path"
shasum -a 256 "$archive_path"
