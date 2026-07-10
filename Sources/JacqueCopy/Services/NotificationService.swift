// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation
#if os(macOS)
import UserNotifications
#endif

/// Manages user notifications for clipboard operations and app events.
public final class NotificationService: ObservableObject {

    // MARK: - Singleton

    public static let shared = NotificationService()

    // MARK: - Published Properties

    /// Whether notifications are enabled by the user.
    @Published public var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    /// Whether notification permission has been granted.
    @Published public private(set) var permissionGranted: Bool = false

    // MARK: - Initialization

    private init() {
        self.notificationsEnabled = UserDefaults.standard.bool(
            forKey: "notificationsEnabled",
            defaultValue: true
        )
        checkPermissionStatus()
    }

    // MARK: - Permission Management

    /// Requests notification permission from the user.
    public func requestPermission() {
        #if os(macOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if let error = error {
                    #if DEBUG
                    print("Notification permission error: \(error.localizedDescription)")
                    #endif
                }
            }
        }
        #else
        // Windows: always granted via tray notifications
        permissionGranted = true
        #endif
    }

    private func checkPermissionStatus() {
        #if os(macOS)
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
        #else
        permissionGranted = true
        #endif
    }

    // MARK: - Notification Delivery

    /// Sends a notification about a clipboard operation.
    public func notifyClipboardCopy(clipboard: ClipboardIdentifier, item: ClipboardItem) {
        guard notificationsEnabled && permissionGranted else { return }
        #if os(macOS)
        deliverNotification(
            title: "Copied to \(clipboard.displayName)",
            body: item.preview,
            identifier: item.id.uuidString
        )
        #else
        print("[\(clipboard.displayName)] Copied: \(item.preview.prefix(50))")
        #endif
    }

    /// Sends a clipboard swap notification.
    public func notifyClipboardSwap() {
        guard notificationsEnabled && permissionGranted else { return }
        #if os(macOS)
        deliverNotification(
            title: "Clipboards Swapped",
            body: "Clipboard A and Clipboard B have been exchanged.",
            identifier: "clipboard-swap"
        )
        #else
        print("Clipboards swapped")
        #endif
    }

    /// Sends a notification when history is cleared.
    public func notifyHistoryCleared(clipboard: ClipboardIdentifier) {
        guard notificationsEnabled && permissionGranted else { return }
        #if os(macOS)
        deliverNotification(
            title: "History Cleared",
            body: "\(clipboard.displayName) history has been cleared.",
            identifier: "history-cleared-\(clipboard.rawValue)"
        )
        #else
        print("\(clipboard.displayName) history cleared")
        #endif
    }

    #if os(macOS)
    // MARK: - Private Helpers

    private func deliverNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("Failed to deliver notification: \(error.localizedDescription)")
                #endif
            }
        }
    }
    #endif
}
