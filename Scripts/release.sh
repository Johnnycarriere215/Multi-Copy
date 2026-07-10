#!/bin/bash
# release.sh - Orchestrate the release process
# Usage: ./Scripts/release.sh <version>
# Example: ./Scripts/release.sh 1.0.0

set -euo pipefail

VERSION="${1:?Please provide a version number (e.g., 1.0.0)}"
BUILD_DIR="build"

echo "=========================================="
echo " Jacque-Copy Release Script"
echo " Version: ${VERSION}"
echo "=========================================="
echo ""

# Step 1: Clean previous builds
echo "[1/5] Cleaning previous build artifacts..."
rm -rf "${BUILD_DIR}/JacqueCopy.app"
rm -f "${BUILD_DIR}/JacqueCopy-${VERSION}.dmg"
rm -f "${BUILD_DIR}/JacqueCopy-${VERSION}.zip"
rm -f "${BUILD_DIR}/SHA256SUMS.txt"
echo "      Done."

# Step 2: Build the application
echo "[2/5] Building Jacque-Copy..."
swift build -c release --arch arm64 --arch x86_64

# Create app bundle structure
echo "[3/5] Creating app bundle..."
mkdir -p "${BUILD_DIR}/JacqueCopy.app/Contents/MacOS"
mkdir -p "${BUILD_DIR}/JacqueCopy.app/Contents/Resources"

# Copy binary (universal)
if [ -f ".build/apple/Products/Release/JacqueCopy" ]; then
    cp ".build/apple/Products/Release/JacqueCopy" "${BUILD_DIR}/JacqueCopy.app/Contents/MacOS/"
else
    # Try individual architectures
    mkdir -p "${BUILD_DIR}/universal"
    lipo -create \
        .build/arm64-apple-macosx/release/JacqueCopy \
        .build/x86_64-apple-macosx/release/JacqueCopy \
        -output "${BUILD_DIR}/universal/JacqueCopy" 2>/dev/null || {
            echo "Warning: Could not create universal binary, using single arch"
            if [ -f ".build/arm64-apple-macosx/release/JacqueCopy" ]; then
                cp ".build/arm64-apple-macosx/release/JacqueCopy" "${BUILD_DIR}/JacqueCopy.app/Contents/MacOS/"
            fi
        }
    if [ -f "${BUILD_DIR}/universal/JacqueCopy" ]; then
        cp "${BUILD_DIR}/universal/JacqueCopy" "${BUILD_DIR}/JacqueCopy.app/Contents/MacOS/"
    fi
fi

# Copy Info.plist
cp Sources/JacqueCopy/Resources/Info.plist "${BUILD_DIR}/JacqueCopy.app/Contents/"

# Copy app icon if available
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "${BUILD_DIR}/JacqueCopy.app/Contents/Resources/"
fi

echo "      Done."

# Step 4: Create DMG and ZIP
echo "[4/5] Creating distribution packages..."
bash Scripts/create-dmg.sh "${VERSION}"
bash Scripts/create-zip.sh "${VERSION}"

# Step 5: Generate checksums
echo "[5/5] Generating SHA-256 checksums..."
cd "${BUILD_DIR}"
cat > SHA256SUMS.txt << EOF
Jacque-Copy v${VERSION} - SHA-256 Checksums
=============================================
EOF

shasum -a 256 "JacqueCopy-${VERSION}.dmg" >> SHA256SUMS.txt
shasum -a 256 "JacqueCopy-${VERSION}.zip" >> SHA256SUMS.txt
cd ..

echo ""
echo "=========================================="
echo " Release ${VERSION} prepared successfully!"
echo "=========================================="
echo ""
echo "Assets:"
echo "  ${BUILD_DIR}/JacqueCopy-${VERSION}.dmg"
echo "  ${BUILD_DIR}/JacqueCopy-${VERSION}.zip"
echo "  ${BUILD_DIR}/SHA256SUMS.txt"
echo ""
echo "Next steps:"
echo "  1. Test the DMG on a clean machine"
echo "  2. Sign and notarize the app"
echo "  3. Create a GitHub release with:"
echo "     gh release create v${VERSION} \\"
echo "       --title \"Jacque-Copy v${VERSION}\" \\"
echo "       --notes-file Documentation/RELEASE_NOTES.md \\"
echo "       ${BUILD_DIR}/JacqueCopy-${VERSION}.dmg \\"
echo "       ${BUILD_DIR}/JacqueCopy-${VERSION}.zip \\"
echo "       ${BUILD_DIR}/SHA256SUMS.txt"
echo ""
