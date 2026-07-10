#!/bin/bash
# generate-icons.sh - Generate app icon PNGs from a 1024x1024 source
# Requires: sips (built-in macOS tool)
# Usage: ./Scripts/generate-icons.sh <1024px-source.png>

set -euo pipefail

SOURCE="${1:?Please provide a 1024x1024 source PNG}"
ASSETS_DIR="Resources/Assets.xcassets/AppIcon.appiconset"

echo "Generating app icon sizes from: ${SOURCE}"

mkdir -p "${ASSETS_DIR}"

# Generate all required sizes
sips -z 1024 1024 "${SOURCE}" --out "${ASSETS_DIR}/icon-1024.png"
sips -z 512 512 "${SOURCE}" --out "${ASSETS_DIR}/icon-512.png"
sips -z 256 256 "${SOURCE}" --out "${ASSETS_DIR}/icon-256.png"
sips -z 128 128 "${SOURCE}" --out "${ASSETS_DIR}/icon-128.png"
sips -z 32 32 "${SOURCE}" --out "${ASSETS_DIR}/icon-32.png"
sips -z 16 16 "${SOURCE}" --out "${ASSETS_DIR}/icon-16.png"

echo "Done! Generated all icon sizes in ${ASSETS_DIR}"
