// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Cross-platform clipboard abstraction.
/// Provides low-level clipboard read/write/change-detection across macOS and Windows.
public protocol ClipboardProvider {
    /// Captures all available representations from the system clipboard.
    func captureCurrent() -> [String: Data]

    /// Writes representations to the system clipboard.
    func writeRepresentations(_ representations: [String: Data])

    /// Checks if the clipboard has changed since last observation.
    func hasChanged() -> Bool

    /// Gets available type identifiers from the clipboard.
    func availableTypes() -> [String]

    /// Gets the bundle identifier of the frontmost application.
    func frontmostApplicationBundleID() -> String?
}

/// Factory for creating the appropriate clipboard provider for the current platform.
public enum ClipboardProviderFactory {
    public static func create() -> ClipboardProvider {
        #if os(Windows)
        return WindowsClipboardProvider()
        #else
        return MacClipboardProvider()
        #endif
    }
}
