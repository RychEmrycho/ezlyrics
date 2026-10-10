#!/bin/bash

# Exit on error
set -e

# Terminate any previously running instances so the newly installed version runs cleanly
killall "ezlyrics" 2>/dev/null || true
killall "ezlyrics (dev)" 2>/dev/null || true

# Build and package the app first
./package.sh --no-dmg

echo "🚀 Installing to /Applications..."
mkdir -p "/Applications"
rm -rf "/Applications/ezlyrics (dev).app"
rm -rf "$HOME/Applications/ezlyrics (dev).app"
mv "ezlyrics (dev).app" "/Applications/"

# Refresh Launch Services and Spotlight metadata
touch "/Applications/ezlyrics (dev).app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/ezlyrics (dev).app" || true

echo "✅ Done! You can now launch 'ezlyrics (dev)' from /Applications/ezlyrics (dev).app"
