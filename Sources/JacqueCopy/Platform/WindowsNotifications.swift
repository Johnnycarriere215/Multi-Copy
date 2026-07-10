// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

// MARK: - Windows-specific Notification Service

#if os(Windows)
import Win32Bridge

/// Windows-specific notification service using system tray balloon notifications.
public final class WindowsNotificationService: ObservableObject {
    public static let shared = WindowsNotificationService()

    @Published public var notificationsEnabled: Bool = true

    private init() {}

    public func notifyClipboardCopy(clipboard: ClipboardIdentifier, item: ClipboardItem) {
        guard notificationsEnabled else { return }
        win32_tray_show_notification(
            "Copied to \(clipboard.displayName)",
            String(item.preview.prefix(100))
        )
    }

    public func notifyClipboardSwap() {
        guard notificationsEnabled else { return }
        win32_tray_show_notification("Clipboards Swapped", "A and B have been exchanged.")
    }

    public func notifyHistoryCleared(clipboard: ClipboardIdentifier) {
        guard notificationsEnabled else { return }
        win32_tray_show_notification("History Cleared", "\(clipboard.displayName) history cleared.")
    }
}
#endif
