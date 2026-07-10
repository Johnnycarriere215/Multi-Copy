# Architecture

## Overview

Jacque-Copy is a macOS menu bar application that provides a dual clipboard system. It uses a combination of SwiftUI and AppKit, following the MVVM architectural pattern with dependency injection.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      JacqueCopyApp                          │
│  ┌─────────────┐  ┌──────────────────────────────────────┐ │
│  │ AppDelegate │  │          SwiftUI Scenes               │ │
│  │             │  │  ┌──────────────┐  ┌──────────────┐  │ │
│  │ • HotkeyMgr │  │  │MenuBarExtra  │  │  Settings    │  │ │
│  │ • Engine    │  │  │  (Popover)   │  │  (Window)    │  │ │
│  └─────────────┘  │  └──────────────┘  └──────────────┘  │ │
│                    │  ┌──────────────────────────────────┐ │ │
│                    │  │    HistoryBrowserView (Sheet)    │ │ │
│                    │  └──────────────────────────────────┘ │ │
│                    └──────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Layer Architecture

### 1. Core Engine Layer

**ClipboardEngine** (`Clipboard/ClipboardEngine.swift`)
- Central nervous system of the application
- Manages both clipboard buffers (system and secondary)
- Coordinates clipboard monitoring, history, and swap operations
- Notifies SwiftUI views of state changes via `@Published` properties

**PasteboardManager** (`Clipboard/PasteboardManager.swift`)
- Low-level NSPasteboard operations
- Captures all available pasteboard representations
- Handles the atomic swap: save Clipboard A, inject Clipboard B, paste, restore
- Thread-safe operations via NSLock
- Filters out sensitive pasteboard types (passwords, transient data)

### 2. Hotkey Layer

**HotkeyManager** (`Hotkeys/HotkeyManager.swift`)
- Uses CGEventTap for global keyboard event interception
- Intercepts Ctrl+C and Ctrl+V globally
- Translates these into clipboard operations
- Requires Accessibility permissions
- Consumes intercepted events to prevent them from reaching target apps

**ShortcutManager** (`Hotkeys/ShortcutManager.swift`)
- User-configurable keyboard shortcuts via KeyboardShortcuts library
- Provides shortcut recorder UI integration
- Handles conflict detection and validation
- Default shortcuts: Ctrl+C for secondary copy, Ctrl+V for secondary paste

### 3. History Layer

**HistoryStore** (`Clipboard/HistoryStore.swift`)
- Persistent history storage using JSON files
- Independent histories for Clipboard A and B
- In-memory cache with lazy loading
- Enforces configurable size and storage limits
- Pinned items are never evicted
- Export/Import support

### 4. Service Layer

**AppSettings** (`Services/AppSettings.swift`)
- Centralized settings with UserDefaults persistence
- Type-safe access with `@Published` properties
- Import/Export settings as JSON
- Factory reset capability

**LaunchService** (`Services/LaunchService.swift`)
- Launch at login via SMAppService
- Dock icon visibility management
- Activation policy configuration

**NotificationService** (`Services/NotificationService.swift`)
- User notification delivery
- Permission management
- Clipboard operation alerts

**UpdateChecker** (`Services/UpdateChecker.swift`)
- Sparkle framework integration
- Automatic and manual update checking

**DiagnosticsService** (`Services/DiagnosticsService.swift`)
- Structured logging with severity levels
- File-based persistent logs
- In-memory log buffer for UI display

### 5. View Layer

**MenuBarContentView** (`Views/MenuBar/MenuBarContentView.swift`)
- Primary UI in the menu bar
- Tabs: Recent, Pinned, Search
- Clipboard A/B preview cards
- Quick actions footer

**SettingsView** (`Views/Settings/SettingsView.swift`)
- Tabbed settings window
- Sections: General, Hotkeys, Clipboard, Appearance, Updates, Advanced
- Form-based layout

**HistoryBrowserView** (`Views/History/HistoryBrowserView.swift`)
- Full clipboard history browser
- Search, filter, sort
- Keyboard navigation (Escape to close, Return to paste)

## Data Flow

### Secondary Copy Flow (Ctrl+C)
```
1. CGEventTap intercepts Ctrl+C
2. HotkeyManager saves current Clipboard A state
3. HotkeyManager simulates Cmd+C via CGEventPost
4. Target app copies to system pasteboard
5. PasteboardManager captures new content from pasteboard
6. ClipboardEngine stores captured item in Clipboard B
7. HistoryStore persists new item to Clipboard B history
8. PasteboardManager restores Clipboard A's original content
```

### Secondary Paste Flow (Ctrl+V)
```
1. CGEventTap intercepts Ctrl+V
2. ClipboardEngine initiates pasteFromClipboardB()
3. PasteboardManager captures current system pasteboard → savedA
4. PasteboardManager writes Clipboard B content to system pasteboard
5. HotkeyManager simulates Cmd+V via CGEventPost
6. Target app pastes Clipboard B content
7. After short delay, PasteboardManager restores savedA
```

## Thread Safety

- PasteboardManager uses NSLock for atomic swap operations
- HistoryStore uses NSLock for cache consistency
- CGEventTap callback runs on the event tap thread
- All state mutations to @Published properties happen on main thread
- DiagnosticsService uses a serial DispatchQueue for log writes

## Performance Considerations

- Timer-based polling at 500ms intervals (standard for clipboard managers)
- Lazy loading: history files loaded only when needed
- In-memory cache avoids repeated disk I/O
- CGEventTap only filters keyDown events, not all events
- No busy loops, no wasted CPU cycles

## Memory Management

- Target idle RAM: < 20 MB
- History cache limited by configurable item count
- Storage size enforced at ~50MB default
- Pinned items protected from eviction
- Weak references used where appropriate (e.g., clipboardEngine in HotkeyManager)
