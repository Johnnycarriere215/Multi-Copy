// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// General application settings: launch behavior, dock, notifications.
struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .help("Automatically start Jacque-Copy when you log in.")

                Toggle("Show Dock Icon", isOn: $settings.showDockIcon)
                    .help("Show Jacque-Copy in the Dock. Changes take effect on next launch.")

                Toggle("Menu Bar Only", isOn: $settings.menuBarOnly)
                    .help("Only show in the menu bar without a Dock icon.")

                Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                    .help("Show notifications for clipboard operations.")

                Toggle("Start Hidden", isOn: $settings.startHidden)
                    .help("Hide the menu bar popover on launch.")
            } header: {
                Label("Startup & Behavior", systemImage: "power")
            }
        }
        .formStyle(.grouped)
    }
}
