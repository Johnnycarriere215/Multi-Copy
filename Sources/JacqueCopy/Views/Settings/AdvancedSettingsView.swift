// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

/// Advanced settings: developer mode, diagnostics, import/export, and reset.
struct AdvancedSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Developer Mode", isOn: $settings.developerMode)
                    .help("Enable additional debugging features and verbose logging.")
                Toggle("Diagnostic Logging", isOn: $settings.diagnosticLogging)
                    .help("Log detailed diagnostic information for troubleshooting.")
            } header: {
                Label("Debugging", systemImage: "ladybug")
            }

            Section {
                HStack {
                    Button("Export Settings") { exportSettings() }
                    Button("Import Settings") { importSettings() }
                }
            } header: {
                Label("Import & Export", systemImage: "arrow.up.arrow.down")
            }

            Section {
                HStack {
                    Button("Backup History") { backupHistory() }
                    Button("Restore History") { restoreHistory() }
                }
            } header: {
                Label("Backup", systemImage: "externaldrive.badge.timemachine")
            }

            Section {
                Button("Reset All Settings", role: .destructive) {
                    AppSettings.shared.resetAllSettings()
                }
            } header: {
                Label("Danger Zone", systemImage: "exclamationmark.triangle")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Import / Export Actions

    private func exportSettings() {
        #if os(macOS)
        if let url = presentSavePanel(defaultName: "JacqueCopy-Settings.json") {
            try? AppSettings.shared.exportSettings(to: url)
        }
        #endif
    }

    private func importSettings() {
        #if os(macOS)
        if let url = presentOpenPanel() {
            try? AppSettings.shared.importSettings(from: url)
        }
        #endif
    }

    private func backupHistory() {
        #if os(macOS)
        let name = "JacqueCopy-Backup-\(Date().ISO8601Format()).json"
        if let url = presentSavePanel(defaultName: name) {
            try? ClipboardEngine.shared.exportHistory(to: url)
        }
        #endif
    }

    private func restoreHistory() {
        #if os(macOS)
        if let url = presentOpenPanel() {
            try? ClipboardEngine.shared.importHistory(from: url)
        }
        #endif
    }

    #if os(macOS)
    private func presentSavePanel(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func presentOpenPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url : nil
    }
    #endif
}
