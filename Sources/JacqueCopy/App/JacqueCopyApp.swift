// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI
import AppKit
import KeyboardShortcuts

/// Main entry point for the Jacque-Copy application.
///
/// This is a menu bar-only application that provides a dual clipboard system.
/// The app uses SwiftUI for the UI layer with AppKit integration for
/// pasteboard operations, event taps, and system integration.
@main
struct JacqueCopyApp: App {

    // MARK: - App Delegate

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - State Objects

    @StateObject private var clipboardEngine = ClipboardEngine.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var shortcutManager = ShortcutManager.shared

    // MARK: - Body

    var body: some Scene {
        // Menu bar item
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(clipboardEngine)
                .environmentObject(settings)
                .environmentObject(shortcutManager)
        } label: {
            MenuBarIconView()
        }
        .menuBarExtraStyle(.menu)

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(shortcutManager)
        }
        .windowResizability(.contentSize)
    }
}

// MARK: - Menu Bar Icon

/// Custom menu bar icon with gold accent that reflects clipboard state.
struct MenuBarIconView: View {
    @EnvironmentObject var clipboardEngine: ClipboardEngine

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 14, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary, Color(hex: "#D4A017"))

            if clipboardEngine.clipboardB != nil {
                Circle()
                    .fill(Color(hex: "#D4A017"))
                    .frame(width: 4, height: 4)
                    .offset(y: 2)
            }
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var hotkeyManager = HotkeyManager.shared
    private var clipboardEngine = ClipboardEngine.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = AppSettings.shared

        // Configure app behavior
        configureAppAppearance()

        // Honor startHidden setting
        if settings.startHidden {
            NSApplication.shared.hide(nil)
        }

        // Start clipboard monitoring
        clipboardEngine.startMonitoring()

        // Start hotkey interception (with accessibility permission check)
        checkAccessibilityPermissions()

        // Setup keyboard shortcut handlers
        setupKeyboardShortcuts()

        // Request notification permission
        NotificationService.shared.requestPermission()

        // Log startup
        DiagnosticsService.shared.info("Jacque-Copy launched successfully", category: "App")
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardEngine.stopMonitoring()
        hotkeyManager.stop()
        DiagnosticsService.shared.info("Jacque-Copy terminated", category: "App")
    }

    // MARK: - Configuration

    private func configureAppAppearance() {
        // Hide from Dock by default (menu bar only)
        if !AppSettings.shared.showDockIcon {
            NSApplication.shared.setActivationPolicy(.accessory)
        }

        // Prevent app from appearing in the cmd+tab switcher
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    // MARK: - Accessibility Permissions

    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if trusted {
            hotkeyManager.start(engine: clipboardEngine)
            DiagnosticsService.shared.info("Accessibility permissions granted", category: "Permissions")
        } else {
            DiagnosticsService.shared.warning("Accessibility permissions required for hotkey interception", category: "Permissions")
        }
    }

    // MARK: - Keyboard Shortcuts

    private func setupKeyboardShortcuts() {
        // Ctrl+C handler is managed by CGEventTap (HotkeyManager)
        // Ctrl+V handler is managed by CGEventTap (HotkeyManager)

        // Toggle history window
        KeyboardShortcuts.onKeyDown(for: .toggleHistoryWindow) { [weak self] in
            // Post notification to show history window
            NotificationCenter.default.post(
                name: .showHistoryWindow,
                object: nil
            )
        }

        // Show menu bar popover
        KeyboardShortcuts.onKeyDown(for: .showMenuBarPopover) {
            // The menu bar extra handles this naturally
        }

        // Clear Clipboard B
        KeyboardShortcuts.onKeyDown(for: .clearClipboardB) { [weak self] in
            self?.clipboardEngine.clearClipboardB()
            NotificationService.shared.notifyHistoryCleared(clipboard: .secondary)
        }

        // Swap clipboards
        KeyboardShortcuts.onKeyDown(for: .swapClipboards) { [weak self] in
            self?.clipboardEngine.swapClipboards()
            NotificationService.shared.notifyClipboardSwap()
        }
    }

    // MARK: - Reopen Handler

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Prevent default dock click behavior
        return false
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the history window should be shown.
    static let showHistoryWindow = Notification.Name("showHistoryWindow")

    /// Posted when clipboard content changes.
    static let clipboardDidChange = Notification.Name("clipboardDidChange")
}

// Color extension (hex init, toHex) is defined in Extensions/ColorExtensions.swift
