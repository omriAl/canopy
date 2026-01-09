#!/bin/bash
set -e

# Generate Canopy app icon and DMG background from Swift-based tools
# Creates AppIcon.icns with all required sizes and dmg-background.png

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ICON_TOOL_DIR="$PROJECT_ROOT/app/Canopy/Tools/IconGenerator"
OUTPUT_DIR="$PROJECT_ROOT/app/Canopy"
DMG_DIR="$OUTPUT_DIR/dmg"
ICONSET_DIR="$OUTPUT_DIR/AppIcon.iconset"
BASE_PNG="$OUTPUT_DIR/icon_1024x1024.png"

echo "=== Generating Canopy Assets ==="

# Step 1: Build the generator tools
echo "Building generator tools..."
cd "$ICON_TOOL_DIR"
swift build -c release

# Step 2: Run IconGenerator to create base 1024x1024 PNG
echo "Generating base icon (1024x1024)..."
.build/release/IconGenerator "$BASE_PNG"

# Step 3: Create iconset directory
echo "Creating iconset with all sizes..."
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Generate all required sizes using sips
# macOS requires these sizes: 16, 32, 128, 256, 512 (plus @2x retina versions)
sips -z 16 16     "$BASE_PNG" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32     "$BASE_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "$BASE_PNG" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64     "$BASE_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "$BASE_PNG" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256   "$BASE_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$BASE_PNG" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512   "$BASE_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$BASE_PNG" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 "$BASE_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

# Step 4: Create .icns file using iconutil
echo "Creating AppIcon.icns..."
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_DIR/AppIcon.icns"

# Step 5: Generate DMG background
echo "Generating DMG background..."
mkdir -p "$DMG_DIR"
.build/release/DMGBackground "$DMG_DIR/dmg-background.png"

# Cleanup
rm -rf "$ICONSET_DIR"
rm -f "$BASE_PNG"

echo "=== Asset generation complete ==="
echo "Outputs:"
echo "  - $OUTPUT_DIR/AppIcon.icns"
echo "  - $DMG_DIR/dmg-background.png"
