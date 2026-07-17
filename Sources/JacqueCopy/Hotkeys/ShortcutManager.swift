// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation
#if os(macOS)
import AppKit
import KeyboardShortcuts
#endif

/// Defines all configurable keyboard shortcuts for Jacque-Copy.
///
/// On macOS, shortcuts use KeyboardShortcuts library for persistence.
/// On Windows, defaults are hardcoded: Alt+C (copy) and Alt+V (paste).
#if os(macOS)
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
#endif

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
    #if os(macOS)
    public var copyToClipboardBShortcut: KeyboardShortcuts.Shortcut? {
        KeyboardShortcuts.getShortcut(for: .copyToClipboardB)
    }
    #endif

    /// Returns the current shortcut for pasting from Clipboard B.
    #if os(macOS)
    public var pasteFromClipboardBShortcut: KeyboardShortcuts.Shortcut? {
        KeyboardShortcuts.getShortcut(for: .pasteFromClipboardB)
    }
    #endif

    /// Returns a human-readable description of the shortcut for Clipboard B copy.
    @MainActor
    public var copyToClipboardBDescription: String {
        #if os(Windows)
        return PlatformServices.defaultCopyShortcutDescription
        #else
        return copyToClipboardBShortcut?.description ?? "Not set"
        #endif
    }

    /// Returns a human-readable description of the shortcut for Clipboard B paste.
    @MainActor
    public var pasteFromClipboardBDescription: String {
        #if os(Windows)
        return PlatformServices.defaultPasteShortcutDescription
        #else
        return pasteFromClipboardBShortcut?.description ?? "Not set"
        #endif
    }

    #if os(macOS)
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

    /// Checks if a key combination conflicts with macOS reserved shortcuts.
    public static func isReservedShortcut(key: KeyboardShortcuts.Key, modifiers: NSEvent.ModifierFlags) -> Bool {
        let reservedCombinations: Set<String> = [
            "\u{2318}Space", "\u{2318}\u{21E7}Space",  // Spotlight
            "\u{2318}\u{21E7}3", "\u{2318}\u{21E7}4", "\u{2318}\u{21E7}5",  // Screenshots
            "\u{2303}\u{2318}Q",                  // Lock Screen
            "\u{2325}\u{2318}Esc",               // Force Quit
            "\u{2303}\u{21E7}Power",             // Sleep
        ]

        var modifierSymbols = ""
        if modifiers.contains(.control) { modifierSymbols += "\u{2303}" }
        if modifiers.contains(.option) { modifierSymbols += "\u{2325}" }
        if modifiers.contains(.shift) { modifierSymbols += "\u{21E7}" }
        if modifiers.contains(.command) { modifierSymbols += "\u{2318}" }

        let description = "\(modifierSymbols)\(key.description)"
        return reservedCombinations.contains(where: { description.contains($0) })
    }
    #else
    /// Resets all shortcuts to their default values (Windows: Alt+C / Alt+V).
    public func resetAllToDefaults() {
        // Windows uses hardcoded Alt+C/V
    }
    #endif
}
