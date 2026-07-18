#!/usr/bin/env bash
#
# Build the Jacque-Copy .deb package.
#
# Usage: packaging/build-deb.sh [VERSION]
# Produces: linux/dist/jacque-copy_<VERSION>_all.deb
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # linux/
ROOT="$HERE"

VERSION="${1:-$(python3 -c "import sys; sys.path.insert(0, '$ROOT'); import jacquecopy; print(jacquecopy.__version__)")}"
PKG="jacque-copy"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo ">> Building $PKG version $VERSION"

# --- filesystem layout ------------------------------------------------
install -d "$STAGE/usr/lib/jacque-copy/jacquecopy"
cp -r "$ROOT/jacquecopy/." "$STAGE/usr/lib/jacque-copy/jacquecopy/"
find "$STAGE/usr/lib/jacque-copy" -name '__pycache__' -type d -prune -exec rm -rf {} +

install -Dm755 "$ROOT/bin/jacque-copy" "$STAGE/usr/bin/jacque-copy"
install -Dm644 "$ROOT/data/jacque-copy.desktop" "$STAGE/usr/share/applications/jacque-copy.desktop"

# Icons (hicolor theme)
install -Dm644 "$ROOT/data/icon.svg" "$STAGE/usr/share/icons/hicolor/scalable/apps/jacque-copy.svg"
for size in 16 24 32 48 64 128 256 512; do
    install -Dm644 "$ROOT/data/icons/jacque-copy-${size}.png" \
        "$STAGE/usr/share/icons/hicolor/${size}x${size}/apps/jacque-copy.png"
done

# --- control metadata -------------------------------------------------
install -d "$STAGE/DEBIAN"
INSTALLED_KB=$(du -sk "$STAGE/usr" | cut -f1)

cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: python3 (>= 3.8), python3-gi, gir1.2-gtk-3.0, gir1.2-keybinder-3.0, gir1.2-ayatanaappindicator3-0.1, python3-xlib
Recommends: xclip
Installed-Size: $INSTALLED_KB
Maintainer: PageFifty <johnny.laine@pagefifty.com>
Homepage: https://github.com/Johnnycarriere215/Multi-Copy
Description: Dual clipboard manager for Linux
 Jacque-Copy adds a second, independent clipboard to your desktop.
 Ctrl+C / Ctrl+V use the normal system clipboard (Clipboard A); Alt+C / Alt+V
 copy and paste an independent second clipboard (Clipboard B). It includes a
 searchable history browser and a system-tray icon.
EOF

cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -f /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi
exit 0
EOF
chmod 755 "$STAGE/DEBIAN/postinst"

cp "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/postrm"

# --- build ------------------------------------------------------------
mkdir -p "$ROOT/dist"
OUT="$ROOT/dist/${PKG}_${VERSION}_all.deb"
if command -v fakeroot >/dev/null 2>&1; then
    fakeroot dpkg-deb --build "$STAGE" "$OUT"
else
    dpkg-deb --root-owner-group --build "$STAGE" "$OUT"
fi

echo ">> Built: $OUT"
