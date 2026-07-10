# Jacque-Copy v1.0.0

## First Public Release

The first stable release of Jacque-Copy — a beautiful dual clipboard built specifically for macOS.

### Highlights

- **True Dual Clipboard**: Two completely independent clipboards (A and B) that never interfere with each other
- **Rich Content**: Preserves every pasteboard representation — text, RTF, HTML, images, files, URLs, and more
- **Clipboard History**: Independent history for each clipboard with configurable size limits
- **Pinned Items & Favorites**: Keep important items permanently accessible
- **Instant Search**: Type to filter across both clipboards instantly
- **Menu Bar App**: Clean, native macOS menu bar interface with clipboard previews
- **Fully Customizable**: Configurable shortcuts, themes (including Black & Gold), accent colors, and animation speeds
- **Performance**: Near-zero CPU usage, under 20 MB RAM, event-driven architecture

### Default Shortcuts

| Action | Shortcut |
|--------|----------|
| Copy (Clipboard A) | ⌘C |
| Paste (Clipboard A) | ⌘V |
| Copy to Clipboard B | ⌃C |
| Paste from Clipboard B | ⌃V |
| Toggle History | ⌘⇧V |

### Requirements

- macOS 14.0 (Sonoma) or later
- Intel or Apple Silicon Mac
- Accessibility permission (required for global hotkey interception)

### Installation

1. Download `JacqueCopy-1.0.0.dmg`
2. Open the DMG
3. Drag Jacque-Copy to Applications
4. Launch and grant Accessibility permissions when prompted

### Known Issues

- First launch may require a restart for hotkeys to work after granting Accessibility permissions
- Some custom pasteboard types from third-party apps may not be fully preserved
- In rare cases, Ctrl+C may not capture content in apps with custom copy handlers

### Checksums

```
JacqueCopy-1.0.0.dmg:
JacqueCopy-1.0.0.zip:
```

*(Checksums will be populated with actual build artifacts)*

---

Built with ❤️ for macOS.
