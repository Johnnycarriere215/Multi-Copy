// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation
#if os(macOS)
import AppKit
#endif

/// Manages low-level clipboard operations for reading, writing, and
/// preserving all available pasteboard representations.
///
/// This is a compatibility layer that delegates to the platform-specific
/// clipboard provider. On macOS, it uses NSPasteboard. On Windows, it
/// uses the Win32 clipboard API.
public final class PasteboardManager {

    // MARK: - Singleton

    public static let shared = PasteboardManager()

    // MARK: - Properties

    private let provider: ClipboardProvider

    /// Lock for thread-safe pasteboard operations.
    private let operationLock = NSLock()

    // MARK: - Initialization

    private init() {
        self.provider = PlatformServices.clipboard
    }

    // MARK: - Public Clipboard Operations

    /// Captures the entire current contents of the system clipboard as a ClipboardItem.
    /// - Returns: A ClipboardItem with all available representations, or nil if empty.
    public func captureCurrentPasteboard() -> ClipboardItem? {
        operationLock.lock()
        defer { operationLock.unlock() }

        let representations = provider.captureCurrent()
        guard !representations.isEmpty else { return nil }

        let preview = ClipboardItem.generatePreview(from: representations)
        let sourceApp = provider.frontmostApplicationBundleID()

        return ClipboardItem(
            id: UUID(),
            preview: preview,
            capturedAt: Date(),
            sourceApplication: sourceApp,
            representations: representations,
            isPinned: false,
            isFavorite: false,
            tags: []
        )
    }

    /// Writes a ClipboardItem's representations back to the system clipboard.
    public func writeToPasteboard(_ item: ClipboardItem) {
        operationLock.lock()
        defer { operationLock.unlock() }
        provider.writeRepresentations(item.representations)
    }

    /// Checks whether the clipboard has changed since the last observation.
    public func hasChanged() -> Bool {
        provider.hasChanged()
    }

    /// Atomically swaps the clipboard content.
    public func atomicSwap(with newContent: ClipboardItem) -> ClipboardItem? {
        operationLock.lock()
        defer { operationLock.unlock() }
        let previous = captureCurrentPasteboard()
        provider.writeRepresentations(newContent.representations)
        return previous
    }

    /// Restores clipboard content.
    public func restorePasteboard(_ item: ClipboardItem?) {
        operationLock.lock()
        defer { operationLock.unlock() }
        if let item = item {
            provider.writeRepresentations(item.representations)
        } else {
            provider.writeRepresentations([:])
        }
    }

    /// Returns the names of all available types on the clipboard.
    public var availableTypes: [String] {
        provider.availableTypes()
    }
}
