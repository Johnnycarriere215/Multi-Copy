<p align="center">
  <img src="https://raw.githubusercontent.com/Johnnycarriere215/Multi-Copy/main/Resources/Assets.xcassets/AppIcon.appiconset/icon-256.png" width="96" height="96" alt="Jacque-Copy">
</p>

# Jacque-Copy v1.0.0

<p align="center"><strong>First public release — a beautiful dual clipboard for macOS and Windows.</strong></p>

<p align="center">
  <a href="https://github.com/Johnnycarriere215/Multi-Copy/releases/download/v1.0.0/JacqueCopy-1.0.0.dmg">
    <img src="https://img.shields.io/badge/%E2%AC%87%20Download%20DMG-macOS%2014%2B-%23D4A017?style=for-the-badge&logo=apple&logoColor=white&labelColor=1C1C1E" alt="Download DMG" height="40">
  </a>
  &nbsp;
  <a href="https://github.com/Johnnycarriere215/Multi-Copy/releases/download/v1.0.0/JacqueCopy-1.0.0-windows.zip">
    <img src="https://img.shields.io/badge/%E2%AC%87%20Download%20ZIP-Windows%2010%2B-%23D4A017?style=for-the-badge&logo=windows&logoColor=white&labelColor=1C1C1E" alt="Download Windows ZIP" height="40">
  </a>
  &nbsp;
  <a href="https://github.com/Johnnycarriere215/Multi-Copy/releases/download/v1.0.0/JacqueCopy-1.0.0.zip">
    <img src="https://img.shields.io/badge/%E2%AC%87%20macOS%20ZIP-14%2B-%23555557?style=for-the-badge&logo=apple&logoColor=white&labelColor=1C1C1E" alt="Download macOS ZIP" height="40">
  </a>
</p>

---

## 📦 Download

| Asset | Type | Size |
|---|---|---|
| **[JacqueCopy-1.0.0.dmg](https://github.com/Johnnycarriere215/Multi-Copy/releases/download/v1.0.0/JacqueCopy-1.0.0.dmg)** | Disk Image (Recommended) | *auto-generated* |
| **[JacqueCopy-1.0.0.zip](https://github.com/Johnnycarriere215/Multi-Copy/releases/download/v1.0.0/JacqueCopy-1.0.0.zip)** | ZIP Archive | *auto-generated* |
| [Source Code (.zip)](https://github.com/Johnnycarriere215/Multi-Copy/archive/refs/tags/v1.0.0.zip) | Source | *auto-generated* |
| [Source Code (.tar.gz)](https://github.com/Johnnycarriere215/Multi-Copy/archive/refs/tags/v1.0.0.tar.gz) | Source | *auto-generated* |

---

## 🚀 Quick Install

### macOS
1. **Download** `JacqueCopy-1.0.0.dmg` above
2. **Open** the DMG file
3. **Drag** Jacque-Copy into your **Applications** folder
4. **Launch** — it appears in your menu bar
5. **Grant** Accessibility permission when prompted
6. **Use** ⌃C to copy to Clipboard B, ⌃V to paste from it

### Windows
1. **Download** `JacqueCopy-1.0.0-windows.zip` above
2. **Extract** the ZIP to any folder
3. **Run** `JacqueCopy.exe` — it appears in your system tray
4. **Use** Alt+C to copy to Clipboard B, Alt+V to paste from it

---

## ✨ Highlights

### 🔀 True Dual Clipboard
Two completely independent clipboards. Clipboard A (⌘C/⌘V) works exactly like macOS always has. Clipboard B (⌃C/⌃V) is a fully separate clipboard that never overwrites A.

### 🎨 Rich Content Preservation
Preserves **every** pasteboard representation: plain text, rich text, RTF, HTML, Markdown, images (PNG, JPEG, TIFF, SVG), PDF, URLs, files, folders, Finder items, and custom types. Nothing is flattened to plain text.

### 📋 Independent History
Each clipboard has its own history with configurable size (10, 25, 50, 100, 250, or unlimited). History persists across reboots with smart deduplication.

### 📌 Pinned Items & Favorites
Pin important items to keep them permanently. Mark favorites for quick access. Search, sort, and filter across both clipboards instantly.

### 🔍 Instant Search
Type to filter — results appear immediately. Arrow keys navigate. Return pastes. Escape closes.

### 🎛️ Fully Customizable
- **Shortcuts**: All six hotkeys are configurable with a built-in recorder and conflict detection
- **Themes**: System, Light, Dark, and **Black & Gold** (default)
- **Accent Color**: Custom color picker
- **Animation Speed**: Fast, Normal, or Slow

### ⚡ Lightweight & Fast
Near-zero idle CPU. Under 20 MB RAM. Event-driven architecture — no polling, no busy loops. Starts instantly.

---

## ⌨️ Default Shortcuts

### macOS

| Action | Shortcut |
|---|---|
| Copy (Clipboard A) | ⌘C |
| Paste (Clipboard A) | ⌘V |
| **Copy to Clipboard B** | **⌃C** |
| **Paste from Clipboard B** | **⌃V** |
| Toggle History Window | ⌘⇧V |
| Show Menu Bar | ⌘⇧J |
| Clear Clipboard B | ⌃⌥X |
| Swap Clipboards | ⌃⌥S |

All configurable in **Settings → Hotkeys**.

### Windows

| Action | Shortcut |
|---|---|
| Copy (Clipboard A) | Ctrl+C |
| Paste (Clipboard A) | Ctrl+V |
| **Copy to Clipboard B** | **Alt+C** |
| **Paste from Clipboard B** | **Alt+V** |
| Clear Clipboard B | Ctrl+Alt+X |
| Swap Clipboards | Ctrl+Alt+S |

---

## 📋 Requirements

| | macOS | Windows |
|---|---|---|
| **OS** | 14.0 (Sonoma) or later | 10 (1809) or later |
| **CPU** | Intel (x86_64) or Apple Silicon (arm64) | x64 or ARM64 |
| **Permissions** | Accessibility (for hotkey interception) | None required |

---

## 🔒 Security

- **Local-only**: All clipboard data stored on your Mac — nothing sent over the network
- **Sensitive data excluded**: Auto-filters password manager types and transient pasteboard data
- **No analytics**: Zero telemetry, zero tracking
- See [SECURITY.md](Documentation/SECURITY.md) for the full policy

---

## ⚠️ Known Issues

- After granting Accessibility permission, you may need to quit and re-open Jacque-Copy for hotkeys to work
- Some custom pasteboard types from third-party apps may not be fully preserved
- In rare cases, apps with custom copy handlers may not work with Ctrl+C (fall back to ⌘C then swap clips)
- Sparkle auto-update feed URL must be configured for your release server

---

## 🔍 Checksums

```
SHA-256:
JacqueCopy-1.0.0.dmg          *(auto-generated at build time)*
JacqueCopy-1.0.0.zip          *(auto-generated at build time)*
JacqueCopy-1.0.0-windows.zip  *(auto-generated at build time)*
```

*Checksums are generated automatically by the CI release workflow and appended to `SHA256SUMS.txt` in the release assets.*

---

## 📚 Full Documentation

- **[README.md](README.md)** — Project overview
- **[INSTALL.md](Documentation/INSTALL.md)** — Detailed installation
- **[BUILD.md](Documentation/BUILD.md)** — Build from source
- **[ARCHITECTURE.md](Documentation/ARCHITECTURE.md)** — Architecture & data flow
- **[FAQ.md](Documentation/FAQ.md)** — Frequently asked questions
- **[CHANGELOG.md](Documentation/CHANGELOG.md)** — Version history
- **[SECURITY.md](Documentation/SECURITY.md)** — Security policy

---

<p align="center">
  <sub>Built with ❤️ for macOS &amp; Windows · MIT Licensed · <a href="https://github.com/Johnnycarriere215/Multi-Copy">github.com/Johnnycarriere215/Multi-Copy</a></sub>
</p>
