// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Platform-specific service locator for injecting platform-dependent implementations.
/// On macOS, uses AppKit/NSPasteboard/CGEventTap.
/// On Windows, uses Win32 clipboard and keyboard hook APIs.
public enum PlatformServices {
    /// The active clipboard provider for the current platform.
    public static let clipboard: ClipboardProvider = ClipboardProviderFactory.create()

    /// The active hotkey provider for the current platform.
    /// Must be initialized with dependencies before use.
    public static var hotkeys: HotkeyProvider?

    /// Whether the current platform is macOS.
    public static var isMacOS: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the current platform is Windows.
    public static var isWindows: Bool {
        #if os(Windows)
        return true
        #else
        return false
        #endif
    }

    /// The default secondary clipboard shortcut label for the current platform.
    public static var defaultSecondaryShortcutLabel: String {
        #if os(Windows)
        return "Alt+C / Alt+V"
        #else
        return "⌃C / ⌃V"
        #endif
    }

    /// The platform display name.
    public static var platformName: String {
        #if os(Windows)
        return "Windows"
        #elseif os(macOS)
        return "macOS"
        #else
        return "Unknown"
        #endif
    }

    /// The default copy shortcut description.
    public static var defaultCopyShortcutDescription: String {
        #if os(Windows)
        return "Alt+C"
        #else
        return "⌃C"
        #endif
    }

    /// The default paste shortcut description.
    public static var defaultPasteShortcutDescription: String {
        #if os(Windows)
        return "Alt+V"
        #else
        return "⌃V"
        #endif
    }
}
