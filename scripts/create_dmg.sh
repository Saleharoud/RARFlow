#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/RARFlow.app"
DMG_PATH="$BUILD_DIR/RARFlow.dmg"
DMG_STAGING="$BUILD_DIR/dmg_staging"

if [ ! -d "$APP_DIR" ]; then
    echo "RARFlow.app not found. Running build_app.sh first..."
    "$SCRIPT_DIR/build_app.sh"
fi

echo "=== Creating RARFlow DMG Package ==="
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"

# Copy RARFlow.app
cp -R "$APP_DIR" "$DMG_STAGING/"

# Create symlink to /Applications
ln -s /Applications "$DMG_STAGING/Applications"

# Create disk image
hdiutil create -volname "RARFlow" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_STAGING"
echo "=== Successfully created DMG at: $DMG_PATH ==="
