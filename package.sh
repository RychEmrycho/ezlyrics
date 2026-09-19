#!/bin/bash

# Exit on error
set -e

GIT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.1")
VERSION="${GIT_VERSION#v}"
BUILD_DMG=true

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-dmg) BUILD_DMG=false ;;
        *) VERSION="$1" ;;
    esac
    shift
done

echo "🎵 Building ezlyrics for Release..."
swift build -c release

# Define paths
if [ "$BUILD_DMG" = true ]; then
    APP_NAME="ezlyrics"
    BUNDLE_ID="com.emrycho.ezlyrics"
    DISPLAY_NAME="ezlyrics"
else
    APP_NAME="ezlyrics (dev)"
    BUNDLE_ID="com.emrycho.ezlyrics.dev"
    DISPLAY_NAME="ezlyrics (dev)"
fi

BUILD_PATH=".build/release/ezlyrics"
APP_DIR="${APP_NAME}.app"
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
    <string>${BUNDLE_ID}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>${DISPLAY_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

if [ "$BUILD_DMG" = true ]; then
    echo "🗜️ Creating Disk Image (DMG)..."
    DMG_STAGING="dmg_staging"
    rm -rf "$DMG_STAGING"
    mkdir -p "$DMG_STAGING"
    cp -R "$APP_DIR" "$DMG_STAGING/"
    ln -s /Applications "$DMG_STAGING/Applications"

    hdiutil create -volname ezlyrics -srcfolder "$DMG_STAGING" -ov -format UDZO "ezlyrics-v${VERSION}.dmg"

    # Clean up staging
    rm -rf "$DMG_STAGING"

    echo "✅ Packaged ezlyrics-v${VERSION}.dmg"
fi
