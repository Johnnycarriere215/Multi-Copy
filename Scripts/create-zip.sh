#!/bin/bash
# create-zip.sh - Create a ZIP file for Jacque-Copy
# Usage: ./Scripts/create-zip.sh [version]

set -euo pipefail

VERSION="${1:-1.0.0}"
APP_NAME="JacqueCopy"
ZIP_NAME="JacqueCopy-${VERSION}"
BUILD_DIR="build"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
ZIP_PATH="${BUILD_DIR}/${ZIP_NAME}.zip"

echo "=========================================="
echo " Creating Jacque-Copy ZIP"
echo " Version: ${VERSION}"
echo "=========================================="

# Ensure the app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "Error: ${APP_PATH} not found. Build the app first."
    exit 1
fi

# Create ZIP
echo "Creating ZIP..."
cd "${BUILD_DIR}"
ditto -c -k --sequesterRsrc --keepParent \
    "${APP_NAME}.app" \
    "${ZIP_NAME}.zip"
cd ..

MV_PATH="${BUILD_DIR}/${ZIP_NAME}.zip"
mv "${BUILD_DIR}/${ZIP_NAME}.zip" "${ZIP_PATH}" 2>/dev/null || true

# Generate checksum
echo "Generating SHA-256 checksum..."
shasum -a 256 "${ZIP_PATH}" > "${ZIP_PATH}.sha256"

echo ""
echo "=========================================="
echo " ZIP created successfully!"
echo " Path: ${ZIP_PATH}"
echo " Size: $(du -h ${ZIP_PATH} | cut -f1)"
echo "=========================================="
