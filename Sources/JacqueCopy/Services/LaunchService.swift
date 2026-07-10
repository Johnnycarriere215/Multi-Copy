// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation
import ServiceManagement
import UserNotifications

/// Manages launch-at-login functionality using the modern SMAppService API.
public final class LaunchService: ObservableObject {

    // MARK: - Singleton

    public static let shared = LaunchService()

    // MARK: - Published Properties

    /// Whether the app is configured to launch at login.
    @Published public var launchAtLogin: Bool {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }

    /// Whether the app should show in the Dock.
    @Published public var showDockIcon: Bool {
        didSet {
            updateDockVisibility()
        }
    }

    // MARK: - Initialization

    private init() {
        self.launchAtLogin = UserDefaults.standard.bool(
            forKey: "launchAtLogin",
            defaultValue: true
        )
        self.showDockIcon = UserDefaults.standard.bool(
            forKey: "showDockIcon",
            defaultValue: false
        )

        // Sync initial state
        if launchAtLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    // MARK: - Private Methods

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        } catch {
            // Log the error but don't crash - the user can enable manually
            #if DEBUG
            print("Failed to update launch at login: \(error.localizedDescription)")
            #endif
        }
    }

    private func updateDockVisibility() {
        if showDockIcon {
            NSApplication.shared.setActivationPolicy(.regular)
        } else {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
        UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon")
    }
}
