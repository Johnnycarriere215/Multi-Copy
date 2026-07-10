#!/bin/bash
# create-dmg.sh - Create a DMG for Jacque-Copy
# Usage: ./Scripts/create-dmg.sh [version]

set -euo pipefail

VERSION="${1:-1.0.0}"
APP_NAME="JacqueCopy"
DMG_NAME="JacqueCopy-${VERSION}"
BUILD_DIR="build"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}.dmg"

echo "=========================================="
echo " Creating Jacque-Copy DMG"
echo " Version: ${VERSION}"
echo "=========================================="

# Ensure the app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "Error: ${APP_PATH} not found. Build the app first."
    exit 1
fi

# Create DMG
echo "Creating DMG..."

if command -v create-dmg &> /dev/null; then
    create-dmg \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 450 185 \
        --volname "Jacque-Copy" \
        --background "${BUILD_DIR}/dmg-background.png" \
        "${DMG_PATH}" \
        "${APP_PATH}" 2>/dev/null || \
    create-dmg \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 450 185 \
        --volname "Jacque-Copy" \
        "${DMG_PATH}" \
        "${APP_PATH}"
else
    # Fallback: use hdiutil directly
    echo "create-dmg not found, using hdiutil..."

    TMP_DMG="${BUILD_DIR}/tmp.dmg"
    hdiutil create -volname "Jacque-Copy" -srcfolder "${APP_PATH}" -ov -format UDRW "${TMP_DMG}"

    # Convert to compressed read-only DMG
    hdiutil convert "${TMP_DMG}" -format UDZO -o "${DMG_PATH}"
    rm -f "${TMP_DMG}"
fi

# Generate checksum
echo "Generating SHA-256 checksum..."
shasum -a 256 "${DMG_PATH}" > "${DMG_PATH}.sha256"

echo ""
echo "=========================================="
echo " DMG created successfully!"
echo " Path: ${DMG_PATH}"
echo " Size: $(du -h ${DMG_PATH} | cut -f1)"
echo "=========================================="
