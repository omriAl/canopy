#!/bin/bash
set -e

# Create DMG installer for Canopy
# Requires: brew install create-dmg

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
APP_NAME="Canopy"
DMG_NAME="${APP_NAME}-Installer"
APP_PATH="$PROJECT_ROOT/app/Canopy/.build/bundler/Canopy.app"
DMG_DIR="$PROJECT_ROOT/dist"
BACKGROUND="$PROJECT_ROOT/app/Canopy/dmg/dmg-background.png"
VOLUME_ICON="$PROJECT_ROOT/app/Canopy/AppIcon.icns"

echo "=== Creating DMG Installer ==="

# Check prerequisites
if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg not found"
    echo "Install with: brew install create-dmg"
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    echo "Run the build first: swift-bundler bundle"
    exit 1
fi

if [ ! -f "$BACKGROUND" ]; then
    echo "Error: DMG background not found at $BACKGROUND"
    echo "Run scripts/generate-icon.sh first"
    exit 1
fi

if [ ! -f "$VOLUME_ICON" ]; then
    echo "Error: App icon not found at $VOLUME_ICON"
    echo "Run scripts/generate-icon.sh first"
    exit 1
fi

# Ensure output directory exists
mkdir -p "$DMG_DIR"

# Remove old DMG if exists
rm -f "$DMG_DIR/$DMG_NAME.dmg"

echo "Creating DMG..."

# Create DMG with create-dmg
create-dmg \
    --volname "$APP_NAME" \
    --volicon "$VOLUME_ICON" \
    --background "$BACKGROUND" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 180 170 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 480 170 \
    --no-internet-enable \
    "$DMG_DIR/$DMG_NAME.dmg" \
    "$APP_PATH"

echo "=== DMG created successfully ==="
echo "Output: $DMG_DIR/$DMG_NAME.dmg"
echo ""
echo "To install:"
echo "  1. Open the DMG"
echo "  2. Drag Canopy to Applications"
echo "  3. Right-click Canopy.app and select 'Open'"
echo "  4. Click 'Open' in the security dialog"
