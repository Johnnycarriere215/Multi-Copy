// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation
import KeyboardShortcuts

/// Defines all configurable keyboard shortcuts for Jacque-Copy.
///
/// Each shortcut is stored in UserDefaults via the KeyboardShortcuts library
/// and can be customized by the user through the Settings UI.
extension KeyboardShortcuts.Name {

    /// Copy to Clipboard B. Default: Control-C
    static let copyToClipboardB = Self(
        "copyToClipboardB",
        default: .init(.c, modifiers: [.control])
    )

    /// Paste from Clipboard B. Default: Control-V
    static let pasteFromClipboardB = Self(
        "pasteFromClipboardB",
        default: .init(.v, modifiers: [.control])
    )

    /// Toggle the clipboard history window. Default: Command-Shift-V
    static let toggleHistoryWindow = Self(
        "toggleHistoryWindow",
        default: .init(.v, modifiers: [.command, .shift])
    )

    /// Show the menu bar popover. Default: Command-Shift-J
    static let showMenuBarPopover = Self(
        "showMenuBarPopover",
        default: .init(.j, modifiers: [.command, .shift])
    )

    /// Clear Clipboard B contents.
    static let clearClipboardB = Self(
        "clearClipboardB",
        default: .init(.x, modifiers: [.control, .option])
    )

    /// Swap the contents of Clipboard A and Clipboard B.
    static let swapClipboards = Self(
        "swapClipboards",
        default: .init(.s, modifiers: [.control, .option])
    )
}

/// Manages all keyboard shortcut configuration for the application.
public final class ShortcutManager: ObservableObject {

    // MARK: - Published Properties

    /// Whether Clipboard B shortcuts are currently enabled.
    @Published public var shortcutsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(shortcutsEnabled, forKey: "shortcutsEnabled")
        }
    }

    // MARK: - Singleton

    public static let shared = ShortcutManager()

    // MARK: - Initialization

    private init() {
        self.shortcutsEnabled = UserDefaults.standard.bool(forKey: "shortcutsEnabled")
    }

    // MARK: - Public Methods

    /// Returns the current shortcut for copying to Clipboard B.
    public var copyToClipboardBShortcut: KeyboardShortcuts.Shortcut? {
        KeyboardShortcuts.getShortcut(for: .copyToClipboardB)
    }

    /// Returns the current shortcut for pasting from Clipboard B.
    public var pasteFromClipboardBShortcut: KeyboardShortcuts.Shortcut? {
        KeyboardShortcuts.getShortcut(for: .pasteFromClipboardB)
    }

    /// Resets all shortcuts to their default values.
    public func resetAllToDefaults() {
        KeyboardShortcuts.reset(.copyToClipboardB)
        KeyboardShortcuts.reset(.pasteFromClipboardB)
        KeyboardShortcuts.reset(.toggleHistoryWindow)
        KeyboardShortcuts.reset(.showMenuBarPopover)
        KeyboardShortcuts.reset(.clearClipboardB)
        KeyboardShortcuts.reset(.swapClipboards)
    }

    /// Removes a specific shortcut (disables it).
    public func removeShortcut(for name: KeyboardShortcuts.Name) {
        KeyboardShortcuts.setShortcut(nil, for: name)
    }

    /// Returns a human-readable description of the shortcut for Clipboard B copy.
    public var copyToClipboardBDescription: String {
        copyToClipboardBShortcut?.description ?? "Not set"
    }

    /// Returns a human-readable description of the shortcut for Clipboard B paste.
    public var pasteFromClipboardBDescription: String {
        pasteFromClipboardBShortcut?.description ?? "Not set"
    }

    /// Checks if a key combination conflicts with macOS reserved shortcuts.
    public static func isReservedShortcut(key: KeyboardShortcuts.Key, modifiers: NSEvent.ModifierFlags) -> Bool {
        let reservedCombinations: Set<String> = [
            "⌘Space", "⌘⇧Space",  // Spotlight
            "⌘⇧3", "⌘⇧4", "⌘⇧5",  // Screenshots
            "⌃⌘Q",                  // Lock Screen
            "⌥⌘Esc",               // Force Quit
            "⌃⇧Power",             // Sleep
        ]

        let description = "\(modifiers.description)\(key.description)"
        return reservedCombinations.contains(where: { description.contains($0) })
    }
}

// MARK: - UserDefaults Convenience (defined in FoundationExtensions)

// Note: UserDefaults convenience methods are defined in FoundationExtensions.swift
// to avoid duplication across the codebase.
