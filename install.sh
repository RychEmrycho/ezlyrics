#!/bin/bash

# Exit on error
set -e

# Build and package the app first
./package.sh --no-dmg

echo "🚀 Installing to ~/Applications..."
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/ezlyrics (dev).app"
mv "ezlyrics (dev).app" "$HOME/Applications/"

# Refresh Launch Services and Spotlight metadata
touch "$HOME/Applications/ezlyrics (dev).app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$HOME/Applications/ezlyrics (dev).app" || true

echo "✅ Done! You can now launch 'ezlyrics (dev)' from ~/Applications/ezlyrics (dev).app"
