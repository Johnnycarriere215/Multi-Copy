// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// Main settings window organized into tabbed sections.
///
/// Settings are persisted through AppSettings and immediately applied.
/// Each tab's content is defined in its own file for maintainability.
struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var shortcutManager: ShortcutManager
    @State private var selectedSection: SettingsSection = .general

    var body: some View {
        TabView(selection: $selectedSection) {
            GeneralSettingsView()
                .environmentObject(settings)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsSection.general)

            HotkeysSettingsView()
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }
                .tag(SettingsSection.hotkeys)

            ClipboardSettingsView()
                .environmentObject(settings)
                .tabItem { Label("Clipboard", systemImage: "doc.on.clipboard") }
                .tag(SettingsSection.clipboard)

            AppearanceSettingsView()
                .environmentObject(settings)
                .tabItem { Label("Appearance", systemImage: "paintpalette") }
                .tag(SettingsSection.appearance)

            UpdatesSettingsView()
                .tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }
                .tag(SettingsSection.updates)

            AdvancedSettingsView()
                .environmentObject(settings)
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
                .tag(SettingsSection.advanced)
        }
        .frame(width: 600, height: 450)
    }
}

/// Identifies each tab in the settings window.
enum SettingsSection: String, CaseIterable, Identifiable {
    case general, hotkeys, clipboard, appearance, updates, advanced
    var id: String { rawValue }
}
