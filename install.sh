#!/bin/bash

# Exit on error
set -e

echo "🎵 Building ezlyrics for Release..."
swift build -c release

# Define paths
BUILD_PATH=".build/release/ezlyrics"
APP_DIR="ezlyrics.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
INFO_PLIST="$APP_DIR/Contents/Info.plist"

echo "📦 Packaging ezlyrics.app..."
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
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "🚀 Installing to ~/Applications..."
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/ezlyrics.app"
mv "$APP_DIR" "$HOME/Applications/"

# Refresh Launch Services and Spotlight metadata
touch "$HOME/Applications/ezlyrics.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$HOME/Applications/ezlyrics.app" || true

echo "✅ Done! You can now launch ezlyrics from ~/Applications/ezlyrics.app"
