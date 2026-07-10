// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// Update preferences: automatic checking, downloads, and manual check.
struct UpdatesSettingsView: View {
    @State private var autoCheck = AppSettings.shared.automaticallyCheckForUpdates
    @State private var autoDownload = AppSettings.shared.downloadUpdatesAutomatically

    var body: some View {
        Form {
            Section {
                Toggle("Automatically Check for Updates", isOn: $autoCheck)
                    .onChange(of: autoCheck) { newValue in
                        AppSettings.shared.automaticallyCheckForUpdates = newValue
                    }
                    .help("Periodically check for new versions of Jacque-Copy.")

                Toggle("Download Updates Automatically", isOn: $autoDownload)
                    .onChange(of: autoDownload) { newValue in
                        AppSettings.shared.downloadUpdatesAutomatically = newValue
                    }
                    .help("Download updates in the background when available.")
            } header: {
                Label("Update Preferences", systemImage: "arrow.triangle.2.circlepath")
            }

            Section {
                UpdaterSettingsView()
            } header: {
                Label("Check Now", systemImage: "magnifyingglass")
            }
        }
        .formStyle(.grouped)
    }
}
