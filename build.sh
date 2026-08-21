#!/bin/bash

# SplitWire-Turkey macOS Build Script
# This script builds the macOS application

set -euo pipefail

APP_NAME="SplitWire-Turkey"
VERSION=${VERSION:-1.1.0}
BUILD_NUMBER=${BUILD_NUMBER:-1}

echo "🔨 Building SplitWire-Turkey for macOS..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf SplitWire-Turkey.app
if [ "${SKIP_BUILD:-0}" != "1" ]; then
    rm -rf .build
fi

# Build the application
if [ "${SKIP_BUILD:-0}" != "1" ]; then
    echo "📦 Building Swift package..."
    swift build -c release --arch x86_64 --scratch-path .build/x86_64
    swift build -c release --arch arm64 --scratch-path .build/arm64
else
    echo "📦 Reusing existing architecture builds..."
fi

UNIVERSAL_BIN_DIR=".build/universal/release"
mkdir -p "${UNIVERSAL_BIN_DIR}"
for EXECUTABLE in "${APP_NAME}" discord-http-proxy; do
    lipo -create \
        ".build/x86_64/x86_64-apple-macosx/release/${EXECUTABLE}" \
        ".build/arm64/arm64-apple-macosx/release/${EXECUTABLE}" \
        -output "${UNIVERSAL_BIN_DIR}/${EXECUTABLE}"
done

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
cp "${UNIVERSAL_BIN_DIR}/${APP_NAME}" "${MACOS}/"

# Copy bundled helper binaries
echo "📋 Copying helper binaries..."
mkdir -p "${RESOURCES}/bin"
if [ -f "Sources/SplitWireTurkey/Resources/bin/ciadpi" ]; then
    cp "Sources/SplitWireTurkey/Resources/bin/ciadpi" "${RESOURCES}/bin/"
    chmod +x "${RESOURCES}/bin/ciadpi"
    echo "  ✓ ByeDPI (ciadpi) copied"
else
    echo "  ✗ Sources/SplitWireTurkey/Resources/bin/ciadpi not found"
    exit 1
fi

cp "${UNIVERSAL_BIN_DIR}/discord-http-proxy" "${RESOURCES}/bin/"
chmod +x "${RESOURCES}/bin/discord-http-proxy"
echo "  ✓ Discord updater proxy copied"

mkdir -p "${RESOURCES}/profiles"
cp "SplitWire-Cloudflare-Encrypted-DNS.mobileconfig" "${RESOURCES}/profiles/"
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
    <string>SplitWire Turkey contributors. MIT License.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "${CONTENTS}/PkgInfo"

# Ad-hoc signing keeps local builds internally consistent. Public releases
# should replace this with Developer ID signing and notarization.
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ Build complete!"
echo "📱 Application bundle created: ${APP_BUNDLE}"
echo ""
echo "To run the application:"
echo "  open ${APP_BUNDLE}"
echo ""
echo "To install to Applications folder:"
echo "  cp -r ${APP_BUNDLE} /Applications/"
