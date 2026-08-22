#!/bin/bash

# DPI Bridge macOS Build Script
# This script builds the macOS application

set -euo pipefail

APP_NAME="DPI-Bridge"
VERSION=${VERSION:-1.2.1}
BUILD_NUMBER=${BUILD_NUMBER:-1}
TARGET_ARCH=${TARGET_ARCH:-universal}

if [[ "${TARGET_ARCH}" != "universal" && "${TARGET_ARCH}" != "x86_64" && "${TARGET_ARCH}" != "arm64" ]]; then
    echo "✗ TARGET_ARCH must be universal, x86_64, or arm64"
    exit 1
fi

echo "🔨 Building DPI Bridge for macOS..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf DPI-Bridge.app
if [ "${SKIP_BUILD:-0}" != "1" ]; then
    rm -rf .build
fi

CIADPI_BUILD=".build/ciadpi/ciadpi"

# Build the application
if [ "${SKIP_BUILD:-0}" != "1" ]; then
    echo "📦 Building ByeDPI from pinned source..."
    TARGET_ARCH="${TARGET_ARCH}" ./scripts/build-ciadpi.sh
    echo "📦 Building Swift package..."
    if [[ "${TARGET_ARCH}" == "universal" || "${TARGET_ARCH}" == "x86_64" ]]; then
        swift build -c release --arch x86_64 --scratch-path .build/x86_64
    fi
    if [[ "${TARGET_ARCH}" == "universal" || "${TARGET_ARCH}" == "arm64" ]]; then
        swift build -c release --arch arm64 --scratch-path .build/arm64
    fi
else
    echo "📦 Reusing existing architecture builds..."
fi

if [[ "${TARGET_ARCH}" == "universal" ]]; then
    OUTPUT_BIN_DIR=".build/universal/release"
    mkdir -p "${OUTPUT_BIN_DIR}"
    for EXECUTABLE in "${APP_NAME}" discord-http-proxy; do
        lipo -create \
            ".build/x86_64/x86_64-apple-macosx/release/${EXECUTABLE}" \
            ".build/arm64/arm64-apple-macosx/release/${EXECUTABLE}" \
            -output "${OUTPUT_BIN_DIR}/${EXECUTABLE}"
    done
else
    OUTPUT_BIN_DIR=".build/${TARGET_ARCH}/${TARGET_ARCH}-apple-macosx/release"
fi

# Create app bundle structure
echo "🎁 Creating application bundle..."
APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

# Copy executable
echo "📋 Copying executable..."
cp "${OUTPUT_BIN_DIR}/${APP_NAME}" "${MACOS}/"

# Copy bundled helper binaries
echo "📋 Copying helper binaries..."
mkdir -p "${RESOURCES}/bin"
if [ -f "${CIADPI_BUILD}" ]; then
    cp "${CIADPI_BUILD}" "${RESOURCES}/bin/ciadpi"
    chmod +x "${RESOURCES}/bin/ciadpi"
    echo "  ✓ ByeDPI (ciadpi) copied"
else
    echo "  ✗ ${CIADPI_BUILD} not found"
    exit 1
fi

cp "${OUTPUT_BIN_DIR}/discord-http-proxy" "${RESOURCES}/bin/"
chmod +x "${RESOURCES}/bin/discord-http-proxy"
echo "  ✓ Discord updater proxy copied"

# SwiftPM release builds contain local DWARF paths unless final executables are
# stripped. Public artifacts must not disclose the build user's filesystem.
strip -S "${MACOS}/${APP_NAME}"
strip -S "${RESOURCES}/bin/discord-http-proxy"

mkdir -p "${RESOURCES}/profiles"
COPYFILE_DISABLE=1 cp -X \
    "DPI-Bridge-Cloudflare-Encrypted-DNS.mobileconfig" "${RESOURCES}/profiles/"
echo "  ✓ Encrypted DNS profile copied"

# Copy App Icon
echo "📋 Copying application icon..."
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${RESOURCES}/"
    echo "  ✓ App icon copied"
else
    echo "  ⚠ Warning: AppIcon.icns not found, skipping..."
fi

# Create Info.plist
echo "📄 Creating Info.plist..."
cat > "${CONTENTS}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.splitwireturkey.macos</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>DPI Bridge contributors. MIT License.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "${CONTENTS}/PkgInfo"

# Ad-hoc signing keeps local builds internally consistent. Public releases
# should replace this with Developer ID signing and notarization.
xattr -cr "${APP_BUNDLE}"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ Build complete!"
echo "📱 Application bundle created: ${APP_BUNDLE}"
echo ""
echo "To run the application:"
echo "  open ${APP_BUNDLE}"
echo ""
echo "To install to Applications folder:"
echo "  cp -r ${APP_BUNDLE} /Applications/"
