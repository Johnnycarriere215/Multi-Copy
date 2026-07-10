# Changelog

All notable changes to Jacque-Copy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-07-10

### Added
- Initial public release
- True dual clipboard system (Clipboard A and Clipboard B)
- Global hotkey interception via CGEventTap for secondary clipboard
- Full pasteboard representation preservation (text, RTF, HTML, images, files, URLs, custom types)
- Independent clipboard history with configurable size limits
- Pinned items and favorites support
- Instant search across both clipboards
- Menu bar application with clipboard preview
- Full settings window (General, Hotkeys, Clipboard, Appearance, Updates, Advanced)
- Configurable keyboard shortcuts with conflict detection
- KeyboardShortcuts library integration for shortcut recording
- Theme support: System, Light, Dark, and Black & Gold
- Custom accent color support
- Sparkle update framework integration
- Launch at login via SMAppService
- Diagnostic logging system
- History import/export
- Settings import/export
- Black & Gold premium design theme (default)
- Native visual effects and animations
- Full documentation suite (README, ARCHITECTURE, BUILD, INSTALL)
- GitHub Actions CI/CD workflows
- MIT License

### Security
- Sensitive pasteboard types excluded from storage
- Local-only data storage
- No network connections for clipboard data

[1.0.0]: https://github.com/Johnnycarriere215/Multi-Copy/releases/tag/v1.0.0
