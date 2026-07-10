// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI
import KeyboardShortcuts

/// Hotkey configuration with per-action shortcut recorders and reset.
struct HotkeysSettingsView: View {
    @State private var shortcutEnabled = UserDefaults.standard.bool(forKey: "shortcutsEnabled", defaultValue: true)

    var body: some View {
        Form {
            Section {
                Toggle("Enable Clipboard B Shortcuts", isOn: $shortcutEnabled)
                    .onChange(of: shortcutEnabled) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "shortcutsEnabled")
                    }
                    .help("Enable or disable the secondary clipboard shortcuts globally.")
            } header: {
                Label("Shortcut State", systemImage: "switch.2")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    shortcutRow(
                        title: "Copy to Clipboard B",
                        subtitle: "Captures the selected content into the secondary clipboard.",
                        name: .copyToClipboardB
                    )
                    Divider()
                    shortcutRow(
                        title: "Paste from Clipboard B",
                        subtitle: "Pastes the secondary clipboard content.",
                        name: .pasteFromClipboardB
                    )
                    Divider()
                    shortcutRow(
                        title: "Toggle History Window",
                        subtitle: "Show or hide the clipboard history browser.",
                        name: .toggleHistoryWindow
                    )
                    Divider()
                    shortcutRow(
                        title: "Show Menu Bar",
                        subtitle: "Open the menu bar popover.",
                        name: .showMenuBarPopover
                    )
                    Divider()
                    shortcutRow(
                        title: "Clear Clipboard B",
                        subtitle: "Wipe the secondary clipboard contents.",
                        name: .clearClipboardB
                    )
                    Divider()
                    shortcutRow(
                        title: "Swap Clipboards",
                        subtitle: "Exchange contents of Clipboard A and B.",
                        name: .swapClipboards
                    )
                }
            } header: {
                Label("Keyboard Shortcuts", systemImage: "keyboard")
            }

            Section {
                HStack {
                    Button("Reset All to Defaults") {
                        ShortcutManager.shared.resetAllToDefaults()
                    }
                }
            } header: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
        }
        .formStyle(.grouped)
    }

    private func shortcutRow(title: String, subtitle: String, name: KeyboardShortcuts.Name) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            KeyboardShortcuts.Recorder(for: name).frame(width: 160)
        }
    }
}
