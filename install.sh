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

# Copy binary
cp "$BUILD_PATH" "$MACOS_DIR/"

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

echo "✅ Done! You can now launch ezlyrics from ~/Applications/ezlyrics.app"
