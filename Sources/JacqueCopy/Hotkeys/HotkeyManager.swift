// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation
#if os(macOS)
import CoreGraphics
import AppKit
import KeyboardShortcuts
#endif

/// Manages global keyboard event interception for secondary clipboard operations.
///
/// On macOS, uses CGEventTap. On Windows, uses low-level keyboard hook.
/// Delegates to the platform-specific HotkeyProvider.
public final class HotkeyManager {

    // MARK: - Singleton

    public static let shared = HotkeyManager()

    // MARK: - Properties

    private var provider: HotkeyProvider?
    private(set) var isActive: Bool = false
    private weak var clipboardEngine: ClipboardEngine?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    @discardableResult
    public func start(engine: ClipboardEngine) -> Bool {
        guard !isActive else { return true }
        self.clipboardEngine = engine

        let hotkeyProvider = HotkeyProviderFactory.create(
            shortcutManager: ShortcutManager.shared,
            clipboardEngine: engine
        )

        let success = hotkeyProvider.startListening(
            copyHandler: { [weak self] in self?.performSecondaryCopy() },
            pasteHandler: { [weak self] in self?.performSecondaryPaste() }
        )

        if success {
            self.provider = hotkeyProvider
            PlatformServices.hotkeys = hotkeyProvider
            isActive = true
        }

        return success
    }

    public func stop() {
        guard isActive else { return }
        isActive = false
        provider?.stopListening()
        provider = nil
    }

    // MARK: - Secondary Copy

    private func performSecondaryCopy() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let savedClipboardA = PasteboardManager.shared.captureCurrentPasteboard()

            // Post synthetic copy (Cmd+C on macOS, Ctrl+C on Windows)
            self.provider?.simulateCopy()

            // After a short delay, capture the result for Clipboard B
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let newItem = PasteboardManager.shared.captureCurrentPasteboard() else {
                    if let saved = savedClipboardA {
                        PasteboardManager.shared.restorePasteboard(saved)
                    }
                    return
                }

                self?.clipboardEngine?.setClipboardBContent(newItem)

                if let saved = savedClipboardA {
                    PasteboardManager.shared.restorePasteboard(saved)
                }
            }
        }
    }

    private func performSecondaryPaste() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            guard let itemB = self.clipboardEngine?.clipboardB else { return }

            let savedClipboardA = PasteboardManager.shared.captureCurrentPasteboard()
            PasteboardManager.shared.writeToPasteboard(itemB)

            // Post synthetic paste (Cmd+V on macOS, Ctrl+V on Windows)
            self.provider?.simulatePaste()

            // Restore Clipboard A after paste processes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                PasteboardManager.shared.restorePasteboard(savedClipboardA)
            }
        }
    }
}
