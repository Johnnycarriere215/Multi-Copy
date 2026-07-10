# Jacque-Copy

<p align="center">
  <img src="Resources/AppIcon.png" alt="Jacque-Copy Icon" width="128" height="128">
</p>

<p align="center">
  <strong>A beautiful dual clipboard built specifically for macOS.</strong>
</p>

<p align="center">
  <a href="https://github.com/jacquecopy/jacque-copy/releases/latest"><img src="https://img.shields.io/github/v/release/jacquecopy/jacque-copy?color=%23D4A017&style=flat-square" alt="Latest Release"></a>
  <a href="https://github.com/jacquecopy/jacque-copy/blob/main/LICENSE"><img src="https://img.shields.io/github/license/jacquecopy/jacque-copy?color=%23D4A017&style=flat-square" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-%23D4A017?style=flat-square" alt="Platform: macOS 14+">
  <a href="https://github.com/jacquecopy/jacque-copy/actions"><img src="https://img.shields.io/github/actions/workflow/status/jacquecopy/jacque-copy/build.yml?style=flat-square" alt="Build Status"></a>
</p>

---

## Why Jacque-Copy?

macOS only provides a single system clipboard. **Jacque-Copy gives you a second, completely independent clipboard.**

This is not clipboard history. This is not multiple tabs. This is literally another clipboard.

- **Clipboard A**: Your normal system clipboard (⌘C / ⌘V). Nothing changes.
- **Clipboard B**: A fully independent secondary clipboard (⌃C / ⌃V by default).

Both behave exactly like native macOS clipboards. Neither overwrites the other.

## Features

### True Dual Clipboard
- Two independent clipboard buffers that never interfere with each other
- Clipboard A uses standard ⌘C / ⌘V -- exactly as macOS works today
- Clipboard B uses configurable shortcuts (default ⌃C / ⌃V)
- Atomic pasteboard swap in milliseconds -- invisible to the user

### Rich Content Preservation
- Preserves every available pasteboard representation
- Supports plain text, rich text, RTF, HTML, Markdown, images (PNG, JPEG, TIFF, SVG), PDF, URLs, files, folders, Finder items, and custom pasteboard types
- No conversion to plain text -- everything is stored exactly as-is

### Clipboard History
- Each clipboard has its own independent history
- Configurable history sizes: 10, 25, 50, 100, 250, or Unlimited
- History persists across reboots
- Smart deduplication to avoid storing identical items

### Pinned Items & Favorites
- Pin important items to prevent them from being removed
- Mark items as favorites for quick access
- Search, sort, and filter across both clipboards

### Instant Search
- Type to filter clipboard history immediately
- Arrow keys navigate, Return pastes, Escape closes
- Searches across both clipboards simultaneously

### Menu Bar Application
- Clean, native menu bar interface
- Quick preview of both clipboards' current content
- Access history, pinned items, and favorites instantly
- Settings, updates, and quit accessible from the menu

### Performance
- Zero idle CPU usage
- Low memory footprint (target &lt; 20 MB)
- Event-driven architecture -- no polling, no busy loops
- Efficient storage with configurable size limits

### Customizable
- Fully configurable keyboard shortcuts
- Shortcut recorder with conflict detection
- Theme support: System, Light, Dark, Black & Gold (default)
- Custom accent colors
- Adjustable animation speeds

## Requirements

- macOS 14.0 (Sonoma) or later
- Intel or Apple Silicon Mac

## Installation

### Via GitHub Releases (Recommended)

1. Download the latest `Jacque-Copy.dmg` from the [Releases](https://github.com/jacquecopy/jacque-copy/releases/latest) page
2. Open the DMG and drag Jacque-Copy to your Applications folder
3. Launch Jacque-Copy from Applications

### Via Homebrew

```bash
# Coming soon
brew install --cask jacque-copy
```

### Build from Source

See [BUILD.md](BUILD.md) for detailed build instructions.

## Usage

### Default Shortcuts

| Action | Shortcut |
|--------|----------|
| Copy (Clipboard A) | ⌘C |
| Paste (Clipboard A) | ⌘V |
| Copy to Clipboard B | ⌃C |
| Paste from Clipboard B | ⌃V |
| Toggle History Window | ⌘⇧V |
| Show Menu Bar | ⌘⇧J |
| Clear Clipboard B | ⌃⌥X |
| Swap Clipboards | ⌃⌥S |

All shortcuts can be customized in Settings > Hotkeys.

### Accessibility Permissions

On first launch, Jacque-Copy will request Accessibility permissions. This is required for the global hotkey interception that powers Clipboard B. Grant the permission in System Settings > Privacy & Security > Accessibility.

## Architecture

Jacque-Copy is built with:
- **Swift** as the primary language
- **SwiftUI** for all user interfaces
- **AppKit** for pasteboard operations and event taps
- **MVVM** architecture with dependency injection
- **Async/Await** for asynchronous operations

For a detailed architecture overview, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Jacque-Copy is released under the [MIT License](LICENSE).

## Acknowledgments

Inspired by the macOS clipboard ecosystem and built with the goal of feeling like a first-party Apple utility.

---

<p align="center">
  <sub>Built with ❤️ for macOS</sub>
</p>
