// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// Clipboard behavior settings: history size, storage, and clearing.
struct ClipboardSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("History Size", selection: $settings.maxHistorySize) {
                    Text("10").tag(10)
                    Text("25").tag(25)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("250").tag(250)
                    Divider()
                    Text("Unlimited").tag(Int.max)
                }
                .help("Maximum number of items stored in each clipboard's history.")

                Picker("Animation Speed", selection: $settings.animationSpeed) {
                    ForEach(AppSettings.AnimationSpeed.allCases, id: \.self) { speed in
                        Text(speed.displayName).tag(speed)
                    }
                }

                Toggle("Preserve Formatting", isOn: $settings.preserveFormatting)
                    .help("Keep rich text, images, and file references when copying.")
            } header: {
                Label("Clipboard Behavior", systemImage: "doc.on.clipboard")
            }

            Section {
                HStack {
                    Text("Storage Size Limit")
                    Spacer()
                    Picker("", selection: $settings.maxStorageSizeMB) {
                        Text("10 MB").tag(10)
                        Text("25 MB").tag(25)
                        Text("50 MB").tag(50)
                        Text("100 MB").tag(100)
                        Text("250 MB").tag(250)
                        Text("500 MB").tag(500)
                    }
                    .labelsHidden()
                }
                .help("Maximum total storage used by clipboard history.")
            } header: {
                Label("Storage", systemImage: "externaldrive")
            }

            Section {
                HStack {
                    Button("Clear Clipboard A History") {
                        ClipboardEngine.shared.clearHistory(for: .system)
                    }
                    Spacer()
                    Button("Clear Clipboard B History") {
                        ClipboardEngine.shared.clearHistory(for: .secondary)
                    }
                }
                Button("Clear All History", role: .destructive) {
                    ClipboardEngine.shared.clearAllHistory()
                }
            } header: {
                Label("Clear History", systemImage: "trash")
            }
        }
        .formStyle(.grouped)
    }
}
