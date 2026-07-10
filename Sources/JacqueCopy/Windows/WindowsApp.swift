// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

#if os(Windows)

import SwiftUI
import Foundation
import Win32Bridge

/// Windows application entry point using SwiftUI App lifecycle.
/// Runs clipboard engine and hotkey interception on a background Win32
/// message loop, while the main thread serves the SwiftUI clipboard window.
@main
struct WindowsApp: App {

    // MARK: - State Objects

    @StateObject private var clipboardEngine = ClipboardEngine.shared
    @StateObject private var settings = AppSettings.shared

    // MARK: - Initialization

    init() {
        // Initialize clipboard engine
        clipboardEngine.startMonitoring()

        // Launch Win32 services (tray + hotkeys) on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            runWin32Services(engine: clipboardEngine)
        }

        // Initialize window management for minimize-to-tray
        // Must run after the SwiftUI window is created, so we schedule it
        // The C bridge handles the tray notification on WM_CLOSE via PostMessage
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            win32_window_init("Jacque-Copy", nil)
        }

        DiagnosticsService.shared.info("Jacque-Copy launched (Windows)", category: "App")
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup("Jacque-Copy") {
            WindowsClipboardWindow()
                .environmentObject(clipboardEngine)
                .environmentObject(settings)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
    }
}

// MARK: - Win32 Services (Background Thread)

/// Runs the Win32 tray icon and hotkey hook on the calling thread.
/// Blocks until the Win32 message loop exits.
private func runWin32Services(engine: ClipboardEngine) {
    // Initialize hotkey provider
    let hotkeyProvider = WindowsHotkeyProvider(
        shortcutManager: ShortcutManager.shared,
        clipboardEngine: engine
    )
    PlatformServices.hotkeys = hotkeyProvider

    // Setup copy/paste handlers
    _ = hotkeyProvider.startListening(
        copyHandler: {
            performSecondaryCopy(engine: engine)
        },
        pasteHandler: {
            performSecondaryPaste(engine: engine)
        }
    )

    // Create system tray icon
    _ = win32_tray_create("Jacque-Copy - Alt+C/V dual clipboard")
    win32_tray_set_click_callback {
        // Restore the app window from tray
        DispatchQueue.main.async {
            win32_show_app_window()
        }
    }

    // Show startup notification
    win32_tray_show_notification(
        "Jacque-Copy",
        "Dual clipboard ready. Alt+C to copy, Alt+V to paste.\nClick tray icon to open history viewer."
    )

    // Run the Windows message loop (blocking)
    win32_run_message_loop()

    // Cleanup on exit
    hotkeyProvider.stopListening()
    engine.stopMonitoring()
    win32_tray_destroy()
}

// MARK: - Secondary Clipboard Operations

/// Copies the current selection to Clipboard B (secondary clipboard).
private func performSecondaryCopy(engine: ClipboardEngine) {
    DispatchQueue.main.async {
        let provider = PlatformServices.clipboard

        // Save current clipboard A content
        let savedClipboardA = provider.captureCurrent()

        // Simulate Ctrl+C to copy current selection
        let hotkeyProvider = PlatformServices.hotkeys
        hotkeyProvider?.simulateCopy()

        // After a short delay, capture the new clipboard content for B
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let newContent = provider.captureCurrent()
            guard !newContent.isEmpty else {
                // Restore previous clipboard A if copy failed
                provider.writeRepresentations(savedClipboardA)
                return
            }

            // Generate preview
            let preview = ClipboardItem.generatePreview(from: newContent)
            let sourceApp = provider.frontmostApplicationBundleID()

            let item = ClipboardItem(
                id: UUID(),
                preview: preview,
                capturedAt: Date(),
                sourceApplication: sourceApp,
                representations: newContent,
                isPinned: false,
                isFavorite: false,
                tags: []
            )

            engine.setClipboardBContent(item)

            // Restore clipboard A
            provider.writeRepresentations(savedClipboardA)

            // Show tray notification
            let previewText = String(item.preview.prefix(50))
            win32_tray_show_notification(
                "Copied to Clipboard B",
                previewText
            )
        }
    }
}

/// Pastes from Clipboard B (secondary clipboard).
private func performSecondaryPaste(engine: ClipboardEngine) {
    DispatchQueue.main.async {
        guard let itemB = engine.clipboardB else { return }

        let provider = PlatformServices.clipboard

        // Save current clipboard A content
        let savedClipboardA = provider.captureCurrent()

        // Write Clipboard B content to system clipboard
        provider.writeRepresentations(itemB.representations)

        // Simulate Ctrl+V to paste
        let hotkeyProvider = PlatformServices.hotkeys
        hotkeyProvider?.simulatePaste()

        // Restore clipboard A after paste completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            provider.writeRepresentations(savedClipboardA)
        }
    }
}

#endif
