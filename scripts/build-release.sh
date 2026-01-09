#!/bin/bash
set -e

# Build Canopy release and create DMG installer
# This is the main release build script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CANOPY_DIR="$PROJECT_ROOT/app/Canopy"

echo "========================================"
echo "       Canopy Release Build"
echo "========================================"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v swift &> /dev/null; then
    echo "Error: Swift not found. Install Xcode Command Line Tools."
    exit 1
fi

if ! [ -f ~/.mint/bin/swift-bundler ]; then
    echo "Error: swift-bundler not found"
    echo "Install with:"
    echo "  brew install mint"
    echo "  mint install stackotter/swift-bundler"
    exit 1
fi

if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg not found"
    echo "Install with: brew install create-dmg"
    exit 1
fi

echo "All prerequisites found."
echo ""

# Step 1: Generate assets (icon and DMG background)
echo "Step 1/4: Generating assets..."
"$SCRIPT_DIR/generate-icon.sh"
echo ""

# Step 2: Build the app with swift-bundler
echo "Step 2/4: Building app bundle..."
cd "$CANOPY_DIR"
~/.mint/bin/swift-bundler bundle --configuration release
echo "App bundle created at: $CANOPY_DIR/.build/bundler/Canopy.app"
echo ""

# Step 3: Bundle terminal-notifier
echo "Step 3/4: Bundling terminal-notifier..."
cp -R "$CANOPY_DIR/Resources/terminal-notifier.app" "$CANOPY_DIR/.build/bundler/Canopy.app/Contents/Resources/"
echo "terminal-notifier bundled into Canopy.app"
echo ""

# Step 4: Create DMG
echo "Step 4/4: Creating DMG installer..."
cd "$PROJECT_ROOT"
"$SCRIPT_DIR/create-dmg.sh"

echo ""
echo "========================================"
echo "       Build Complete!"
echo "========================================"
echo ""
echo "Output: $PROJECT_ROOT/dist/Canopy-Installer.dmg"
echo ""
echo "To test locally:"
echo "  open dist/Canopy-Installer.dmg"
