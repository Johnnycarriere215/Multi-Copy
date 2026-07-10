// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// Advanced settings: developer mode, diagnostics, import/export, and reset.
struct AdvancedSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    @State private var showExportPicker = false
    @State private var showImportPicker = false
    @State private var showBackupPicker = false
    @State private var showRestorePicker = false

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
                    Button("Export Settings") { showExportPicker = true }
                        .fileExporter(
                            isPresented: $showExportPicker,
                            document: nil,
                            contentType: .json,
                            defaultFilename: "JacqueCopy-Settings.json"
                        ) { result in
                            if case .success(let url) = result {
                                try? AppSettings.shared.exportSettings(to: url)
                            }
                        }

                    Button("Import Settings") { showImportPicker = true }
                        .fileImporter(
                            isPresented: $showImportPicker,
                            allowedContentTypes: [.json]
                        ) { result in
                            if case .success(let url) = result {
                                try? AppSettings.shared.importSettings(from: url)
                            }
                        }
                }
            } header: {
                Label("Import & Export", systemImage: "arrow.up.arrow.down")
            }

            Section {
                HStack {
                    Button("Backup History") { showBackupPicker = true }
                        .fileExporter(
                            isPresented: $showBackupPicker,
                            document: nil,
                            contentType: .json,
                            defaultFilename: "JacqueCopy-Backup-\(Date().ISO8601Format()).json"
                        ) { result in
                            if case .success(let url) = result {
                                try? ClipboardEngine.shared.exportHistory(to: url)
                            }
                        }

                    Button("Restore History") { showRestorePicker = true }
                        .fileImporter(
                            isPresented: $showRestorePicker,
                            allowedContentTypes: [.json]
                        ) { result in
                            if case .success(let url) = result {
                                try? ClipboardEngine.shared.importHistory(from: url)
                            }
                        }
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
}
