// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Cross-platform hotkey management abstraction.
/// Handles global keyboard event interception and synthetic key presses.
public protocol HotkeyProvider {
    /// Starts intercepting global hotkeys.
    /// - Parameters:
    ///   - copyHandler: Called when the secondary copy shortcut is pressed.
    ///   - pasteHandler: Called when the secondary paste shortcut is pressed.
    /// - Returns: true if successfully started, false otherwise.
    func startListening(copyHandler: @escaping () -> Void, pasteHandler: @escaping () -> Void) -> Bool

    /// Stops intercepting global hotkeys.
    func stopListening()

    /// Checks if hotkey interception is currently active.
    var isActive: Bool { get }

    /// Posts a synthetic Cmd+C / Ctrl+C to capture current selection.
    func simulateCopy()

    /// Posts a synthetic Cmd+V / Ctrl+V to paste current content.
    func simulatePaste()
}

/// Factory for creating the appropriate hotkey provider for the current platform.
public enum HotkeyProviderFactory {
    public static func create(shortcutManager: ShortcutManager, clipboardEngine: ClipboardEngine) -> HotkeyProvider {
        #if os(Windows)
        return WindowsHotkeyProvider(shortcutManager: shortcutManager, clipboardEngine: clipboardEngine)
        #else
        return MacHotkeyProvider(shortcutManager: shortcutManager, clipboardEngine: clipboardEngine)
        #endif
    }
}
