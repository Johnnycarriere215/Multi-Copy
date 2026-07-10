// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation
#if os(macOS)
import ServiceManagement
import AppKit
#endif

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

    /// Whether the app should show in the Dock (macOS only).
    @Published public var showDockIcon: Bool {
        didSet {
            #if os(macOS)
            updateDockVisibility()
            #endif
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

        #if os(macOS)
        // Sync initial state
        if launchAtLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
        #endif
    }

    // MARK: - Private Methods

    private func setLaunchAtLogin(_ enabled: Bool) {
        #if os(macOS)
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            #if DEBUG
            print("Failed to update launch at login: \(error.localizedDescription)")
            #endif
        }
        #endif
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
    }

    #if os(macOS)
    private func updateDockVisibility() {
        if showDockIcon {
            NSApplication.shared.setActivationPolicy(.regular)
        } else {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
        UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon")
    }
    #endif
}
