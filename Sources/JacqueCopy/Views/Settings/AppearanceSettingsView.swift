// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// Appearance settings: theme selection and accent color.
struct AppearanceSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(AppSettings.Theme.allCases, id: \.self) { theme in
                        HStack {
                            Image(systemName: themeIcon(for: theme))
                            Text(theme.displayName)
                        }
                        .tag(theme)
                    }
                }
                .help("Choose the visual theme for Jacque-Copy.")

                ColorPicker("Accent Color", selection: Binding(
                    get: { Color(hex: settings.accentColor) },
                    set: { settings.accentColor = $0.toHex() }
                ))
                .help("Customize the accent color used throughout the app.")
            } header: {
                Label("Theme", systemImage: "paintpalette")
            }
        }
        .formStyle(.grouped)
    }

    private func themeIcon(for theme: AppSettings.Theme) -> String {
        switch theme {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        case .blackGold: return "sparkles"
        }
    }
}
