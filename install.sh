#!/bin/bash

# Exit on error
set -e

# Build and package the app first
./package.sh

echo "🚀 Installing to ~/Applications..."
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/ezlyrics.app"
mv ezlyrics.app "$HOME/Applications/"

# Clean up dmg
rm -f ezlyrics-*.dmg

# Refresh Launch Services and Spotlight metadata
touch "$HOME/Applications/ezlyrics.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$HOME/Applications/ezlyrics.app" || true

echo "✅ Done! You can now launch ezlyrics from ~/Applications/ezlyrics.app"
