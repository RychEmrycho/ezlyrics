#!/bin/bash

# Exit on error
set -e

VERSION=${1:-"0.0.1"}

echo "🎵 Building ezlyrics for Release..."
swift build -c release

# Define paths
BUILD_PATH=".build/release/ezlyrics"
APP_DIR="ezlyrics.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
INFO_PLIST="$APP_DIR/Contents/Info.plist"

echo "📦 Packaging ezlyrics.app (Version: $VERSION)..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary and icon
cp "$BUILD_PATH" "$MACOS_DIR/"
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# Create basic Info.plist
cat > "$INFO_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ezlyrics</string>
    <key>CFBundleIdentifier</key>
    <string>com.emrycho.ezlyrics</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>ezlyrics</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "🗜️ Creating Disk Image (DMG)..."
hdiutil create -volname ezlyrics -srcfolder ezlyrics.app -ov -format UDZO "ezlyrics-v${VERSION}.dmg"

echo "✅ Packaged ezlyrics-v${VERSION}.dmg"
