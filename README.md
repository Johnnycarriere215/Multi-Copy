<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Resources/Assets.xcassets/AppIcon.appiconset/icon-256.png">
    <img src="Resources/Assets.xcassets/AppIcon.appiconset/icon-256.png" alt="Jacque-Copy" width="128" height="128">
  </picture>
</p>

<h1 align="center">Jacque-Copy</h1>

<p align="center"><strong>A beautiful dual clipboard built for macOS and Windows.</strong></p>

<p align="center">
  <a href="https://github.com/Johnnycarriere215/Multi-Copy/releases/latest"><img src="https://img.shields.io/github/v/release/Johnnycarriere215/Multi-Copy?color=%23D4A017&style=for-the-badge" alt="Latest Release"></a>
  <a href="https://github.com/Johnnycarriere215/Multi-Copy/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Johnnycarriere215/Multi-Copy?color=%23D4A017&style=for-the-badge" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-%23D4A017?style=for-the-badge" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Windows-10%2B-%23D4A017?style=for-the-badge" alt="Windows 10+">
  <a href="https://github.com/Johnnycarriere215/Multi-Copy/actions"><img src="https://img.shields.io/github/actions/workflow/status/Johnnycarriere215/Multi-Copy/build.yml?style=for-the-badge" alt="Build"></a>
</p>

---

<p align="center">
  <a href="https://github.com/Johnnycarriere215/Multi-Copy/releases/latest">
    <img src="https://img.shields.io/badge/%E2%AC%87%20Download-Latest%20Release-%23D4A017?style=for-the-badge&logo=github&logoColor=white&labelColor=1C1C1E" alt="Download Latest Release" height="48">
  </a>
</p>

<p align="center">
  <sub>macOS 14+ &nbsp;·&nbsp; Windows 10+ &nbsp;·&nbsp; Intel &amp; Apple Silicon &nbsp;·&nbsp; x64 &amp; ARM64 &nbsp;·&nbsp; Free &amp; Open Source</sub>
</p>

---

## What is Jacque-Copy?

Your operating system gives you **one** system clipboard. Jacque-Copy gives you a **second**, completely independent one.

This is not clipboard history. Not multiple tabs. Not categories. **It's literally another clipboard.**

| | macOS | Windows |
|---|---|---|
| Clipboard A | ⌘C / ⌘V | Ctrl+C / Ctrl+V |
| Clipboard B | ⌃C / ⌃V | **Alt+C / Alt+V** |
| **Nothing changes** — your OS works exactly as before | | |

> Copy `Apple` with Ctrl+C, then copy `Orange` with Alt+C. Press Ctrl+V → you get `Apple`. Press Alt+V → you get `Orange`. Neither clipboard ever destroys the other.

---

## 🚀 Quick Start

### macOS

**[→ Download the latest DMG from GitHub Releases](https://github.com/Johnnycarriere215/Multi-Copy/releases/latest)**

Get `JacqueCopy-*.dmg` from the latest release. Open the DMG, drag to Applications, launch. Grant Accessibility permission when prompted.

Use **⌃C** to copy to Clipboard B and **⌃V** to paste from it.

### Windows

**[→ Download the latest Windows release](https://github.com/Johnnycarriere215/Multi-Copy/releases/latest)**

Get `JacqueCopy-*-windows.zip` from the latest release. Extract and run `JacqueCopy.exe`. The app runs from the system tray.

Use **Alt+C** to copy to Clipboard B and **Alt+V** to paste from it.

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🔀 True Dual Clipboard
Two independent clipboards that never interfere. Clipboard A uses ⌘C/⌘V exactly as macOS works today. Clipboard B uses ⌃C/⌃V — fully configurable.

### 🎨 Rich Content
Preserves **every** pasteboard representation. Plain text, rich text, RTF, HTML, Markdown, images (PNG, JPEG, TIFF, SVG), PDF, URLs, files, folders — stored exactly as-is.

### 📋 History
Each clipboard has its own independent history. Configurable sizes from 10 to unlimited. Smart deduplication. Persists across reboots.

</td>
<td width="50%">

### 📌 Pinned & Favorites
Pin important items. Mark favorites. Search, sort, and filter across both clipboards instantly.

### 🔍 Instant Search
Type to filter history immediately. Arrow keys to navigate. Return to paste. Escape to close.

### 🎛️ Fully Customizable
Custom shortcuts with conflict detection. Four themes: System, Light, Dark, and **Black & Gold** (default). Custom accent colors. Adjustable animation speeds.

### ⚡ Lightweight
Zero idle CPU. Under 20 MB RAM. Event-driven — no polling, no busy loops. Native performance.

</td>
</tr>
</table>

---

## ⌨️ Default Shortcuts

### macOS

| Action | Shortcut | Description |
|---|---|---|
| Copy (Clipboard A) | ⌘C | Normal macOS copy |
| Paste (Clipboard A) | ⌘V | Normal macOS paste |
| **Copy to B** | **⌃C** | Copy selected content to secondary clipboard |
| **Paste from B** | **⌃V** | Paste secondary clipboard content |
| Toggle History | ⌘⇧V | Open/close the full history browser |
| Show Menu Bar | ⌘⇧J | Open the menu bar popover |
| Clear Clipboard B | ⌃⌥X | Wipe the secondary clipboard |
| Swap Clipboards | ⌃⌥S | Exchange contents of A and B |

### Windows

| Action | Shortcut | Description |
|---|---|---|
| Copy (Clipboard A) | Ctrl+C | Normal Windows copy |
| Paste (Clipboard A) | Ctrl+V | Normal Windows paste |
| **Copy to B** | **Alt+C** | Copy selected content to secondary clipboard |
| **Paste from B** | **Alt+V** | Paste secondary clipboard content |
| Clear Clipboard B | Ctrl+Alt+X | Wipe the secondary clipboard |
| Swap Clipboards | Ctrl+Alt+S | Exchange contents of A and B |

---

## 📦 Installation

### Option 1: Download (Recommended)

**[→ Get the latest release](https://github.com/Johnnycarriere215/Multi-Copy/releases/latest)**

- **macOS**: Download the DMG, drag to Applications, done.
- **Windows**: Download the ZIP, extract, run `JacqueCopy.exe`.

### Option 2: Homebrew *(macOS, coming soon)*

```bash
brew install --cask jacque-copy
```

### Option 3: Build from Source

```bash
git clone https://github.com/Johnnycarriere215/Multi-Copy.git
cd jacque-copy

# macOS
xed .                         # open in Xcode
swift build -c release        # or build from command line

# Windows
swift build -c release        # requires Swift for Windows
```

See [BUILD.md](Documentation/BUILD.md) for detailed instructions including signing and notarization.

---

## 📋 Requirements

| | macOS | Windows |
|---|---|---|
| **OS** | 14.0 (Sonoma) or later | 10 (1809) or later |
| **CPU** | Intel (x86_64) or Apple Silicon (arm64) | x64 or ARM64 |
| **Permission** | Accessibility (for hotkey interception) | None required |

---

## 🏗️ Architecture

Built with **Swift** + **SwiftUI** + **AppKit** using MVVM architecture with dependency injection and async/await.

```
CGEventTap → HotkeyManager → ClipboardEngine → PasteboardManager → NSPasteboard
                                  ↕
                             HistoryStore → JSON files on disk
                                  ↕
                     SwiftUI Views (MenuBar, Settings, History)
```

For a detailed breakdown, see [ARCHITECTURE.md](Documentation/ARCHITECTURE.md).

---

## 📚 More Documentation

| Document | |
|---|---|
| [INSTALL.md](Documentation/INSTALL.md) | Full installation guide with permissions setup |
| [BUILD.md](Documentation/BUILD.md) | Build from source, signing, notarization |
| [ARCHITECTURE.md](Documentation/ARCHITECTURE.md) | Architecture and data flow |
| [FAQ.md](Documentation/FAQ.md) | Frequently asked questions |
| [CHANGELOG.md](Documentation/CHANGELOG.md) | Version history |
| [ROADMAP.md](Documentation/ROADMAP.md) | Future plans |
| [SECURITY.md](Documentation/SECURITY.md) | Security policy |

---

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](Documentation/CONTRIBUTING.md) for guidelines.

---

## 📄 License

Jacque-Copy is [MIT licensed](LICENSE). Free, open source, forever.

---

<p align="center">
  <sub>Built with ❤️ for macOS &amp; Windows &nbsp;·&nbsp; Not affiliated with Apple Inc. or Microsoft.</sub>
</p>
