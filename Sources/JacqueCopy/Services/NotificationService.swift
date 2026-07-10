// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation
import UserNotifications

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
    }

    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Notification Delivery

    /// Sends a notification about a clipboard operation.
    public func notifyClipboardCopy(clipboard: ClipboardIdentifier, item: ClipboardItem) {
        guard notificationsEnabled && permissionGranted else { return }
        deliverNotification(
            title: "Copied to \(clipboard.displayName)",
            body: item.preview,
            identifier: item.id.uuidString
        )
    }

    /// Sends a clipboard swap notification.
    public func notifyClipboardSwap() {
        guard notificationsEnabled && permissionGranted else { return }
        deliverNotification(
            title: "Clipboards Swapped",
            body: "Clipboard A and Clipboard B have been exchanged.",
            identifier: "clipboard-swap"
        )
    }

    /// Sends a notification when history is cleared.
    public func notifyHistoryCleared(clipboard: ClipboardIdentifier) {
        guard notificationsEnabled && permissionGranted else { return }
        deliverNotification(
            title: "History Cleared",
            body: "\(clipboard.displayName) history has been cleared.",
            identifier: "history-cleared-\(clipboard.rawValue)"
        )
    }

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
}
