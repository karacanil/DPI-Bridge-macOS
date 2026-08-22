#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
REPO_ROOT=${SCRIPT_DIR:h}
SOURCE_DIR="$REPO_ROOT/byedpi"
OUTPUT_ROOT="$REPO_ROOT/.build/ciadpi"
TARGET_ARCH=${TARGET_ARCH:-universal}

case "$TARGET_ARCH" in
    universal) ARCHITECTURES=(x86_64 arm64) ;;
    x86_64|arm64) ARCHITECTURES=($TARGET_ARCH) ;;
    *) print -u2 "HATA: TARGET_ARCH universal, x86_64 veya arm64 olmalı."; exit 1 ;;
esac

SOURCES=(packets.c main.c conev.c proxy.c desync.c mpool.c extend.c)
mkdir -p "$OUTPUT_ROOT"

for architecture in "${ARCHITECTURES[@]}"; do
    output_dir="$OUTPUT_ROOT/$architecture"
    mkdir -p "$output_dir"
    source_paths=()
    for source_file in "${SOURCES[@]}"; do
        source_paths+=("$SOURCE_DIR/$source_file")
    done

    print "ByeDPI $architecture derleniyor..."
    xcrun --sdk macosx clang \
        -arch "$architecture" \
        -mmacosx-version-min=13.0 \
        -D_DEFAULT_SOURCE \
        -I"$SOURCE_DIR" \
        -std=c99 -O2 -Wall -Wextra -Wno-unused -Wno-unused-parameter -pedantic \
        "${source_paths[@]}" \
        -o "$output_dir/ciadpi"
    strip -S "$output_dir/ciadpi"
done

if [[ "$TARGET_ARCH" == universal ]]; then
    lipo -create \
        "$OUTPUT_ROOT/x86_64/ciadpi" \
        "$OUTPUT_ROOT/arm64/ciadpi" \
        -output "$OUTPUT_ROOT/ciadpi"
else
    cp "$OUTPUT_ROOT/$TARGET_ARCH/ciadpi" "$OUTPUT_ROOT/ciadpi"
fi

chmod +x "$OUTPUT_ROOT/ciadpi"
print "ByeDPI hazır: $OUTPUT_ROOT/ciadpi ($(lipo -archs "$OUTPUT_ROOT/ciadpi"))"
