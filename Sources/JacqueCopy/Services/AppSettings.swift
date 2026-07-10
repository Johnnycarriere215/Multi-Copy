// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Centralized settings management with UserDefaults persistence and Codable support.
///
/// AppSettings provides type-safe access to all application settings with
/// proper defaults, validation, and change observation via Combine.
public final class AppSettings: ObservableObject {

    // MARK: - Singleton

    public static let shared = AppSettings()

    // MARK: - General Settings

    @Published public var launchAtLogin: Bool {
        didSet { persist(key: "launchAtLogin", value: launchAtLogin) }
    }

    @Published public var showDockIcon: Bool {
        didSet { persist(key: "showDockIcon", value: showDockIcon) }
    }

    @Published public var menuBarOnly: Bool {
        didSet { persist(key: "menuBarOnly", value: menuBarOnly) }
    }

    @Published public var notificationsEnabled: Bool {
        didSet { persist(key: "notificationsEnabled", value: notificationsEnabled) }
    }

    @Published public var startHidden: Bool {
        didSet { persist(key: "startHidden", value: startHidden) }
    }

    // MARK: - Clipboard Settings

    @Published public var maxHistorySize: Int {
        didSet { persist(key: "maxHistorySize", value: maxHistorySize) }
    }

    @Published public var preserveFormatting: Bool {
        didSet { persist(key: "preserveFormatting", value: preserveFormatting) }
    }

    @Published public var maxStorageSizeMB: Int {
        didSet { persist(key: "maxStorageSizeMB", value: maxStorageSizeMB) }
    }

    // MARK: - Appearance Settings

    public enum Theme: String, CaseIterable, Codable {
        case system
        case light
        case dark
        case blackGold

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            case .blackGold: return "Black & Gold"
            }
        }
    }

    @Published public var theme: Theme {
        didSet { persist(key: "theme", value: theme.rawValue) }
    }

    @Published public var accentColor: String {
        didSet { persist(key: "accentColor", value: accentColor) }
    }

    public enum AnimationSpeed: String, CaseIterable, Codable {
        case fast
        case normal
        case slow

        var displayName: String {
            switch self {
            case .fast: return "Fast"
            case .normal: return "Normal"
            case .slow: return "Slow"
            }
        }

        var duration: Double {
            switch self {
            case .fast: return 0.15
            case .normal: return 0.25
            case .slow: return 0.40
            }
        }
    }

    @Published public var animationSpeed: AnimationSpeed {
        didSet { persist(key: "animationSpeed", value: animationSpeed.rawValue) }
    }

    // MARK: - Update Settings

    @Published public var automaticallyCheckForUpdates: Bool {
        didSet { persist(key: "automaticallyCheckForUpdates", value: automaticallyCheckForUpdates) }
    }

    @Published public var downloadUpdatesAutomatically: Bool {
        didSet { persist(key: "downloadUpdatesAutomatically", value: downloadUpdatesAutomatically) }
    }

    // MARK: - Advanced Settings

    @Published public var developerMode: Bool {
        didSet { persist(key: "developerMode", value: developerMode) }
    }

    @Published public var diagnosticLogging: Bool {
        didSet { persist(key: "diagnosticLogging", value: diagnosticLogging) }
    }

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.standard

        // General
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin", defaultValue: true)
        self.showDockIcon = defaults.bool(forKey: "showDockIcon", defaultValue: false)
        self.menuBarOnly = defaults.bool(forKey: "menuBarOnly", defaultValue: true)
        self.notificationsEnabled = defaults.bool(forKey: "notificationsEnabled", defaultValue: true)
        self.startHidden = defaults.bool(forKey: "startHidden", defaultValue: true)

        // Clipboard
        self.maxHistorySize = defaults.integer(forKey: "maxHistorySize", defaultValue: 100)
        self.preserveFormatting = defaults.bool(forKey: "preserveFormatting", defaultValue: true)
        self.maxStorageSizeMB = defaults.integer(forKey: "maxStorageSizeMB", defaultValue: 50)

        // Appearance
        let themeRaw = defaults.string(forKey: "theme", defaultValue: Theme.blackGold.rawValue)
        self.theme = Theme(rawValue: themeRaw) ?? .blackGold
        self.accentColor = defaults.string(forKey: "accentColor", defaultValue: "#D4A017")

        let animRaw = defaults.string(forKey: "animationSpeed", defaultValue: AnimationSpeed.normal.rawValue)
        self.animationSpeed = AnimationSpeed(rawValue: animRaw) ?? .normal

        // Updates
        self.automaticallyCheckForUpdates = defaults.bool(forKey: "automaticallyCheckForUpdates", defaultValue: true)
        self.downloadUpdatesAutomatically = defaults.bool(forKey: "downloadUpdatesAutomatically", defaultValue: false)

        // Advanced
        self.developerMode = defaults.bool(forKey: "developerMode", defaultValue: false)
        self.diagnosticLogging = defaults.bool(forKey: "diagnosticLogging", defaultValue: false)
    }

    // MARK: - Persistence Helpers

    private func persist(key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }

    // MARK: - Export/Import

    /// Exports all settings to a JSON file.
    public func exportSettings(to url: URL) throws {
        let settings: [String: Any] = [
            "launchAtLogin": launchAtLogin,
            "showDockIcon": showDockIcon,
            "menuBarOnly": menuBarOnly,
            "notificationsEnabled": notificationsEnabled,
            "startHidden": startHidden,
            "maxHistorySize": maxHistorySize,
            "preserveFormatting": preserveFormatting,
            "maxStorageSizeMB": maxStorageSizeMB,
            "theme": theme.rawValue,
            "accentColor": accentColor,
            "animationSpeed": animationSpeed.rawValue,
            "automaticallyCheckForUpdates": automaticallyCheckForUpdates,
            "downloadUpdatesAutomatically": downloadUpdatesAutomatically,
            "developerMode": developerMode,
            "diagnosticLogging": diagnosticLogging
        ]

        let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url)
    }

    /// Imports settings from a JSON file.
    public func importSettings(from url: URL) throws {
        let data = try Data(contentsOf: url)
        guard let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ImportError.invalidFormat
        }

        // Apply each setting
        if let value = settings["launchAtLogin"] as? Bool { launchAtLogin = value }
        if let value = settings["showDockIcon"] as? Bool { showDockIcon = value }
        if let value = settings["menuBarOnly"] as? Bool { menuBarOnly = value }
        if let value = settings["notificationsEnabled"] as? Bool { notificationsEnabled = value }
        if let value = settings["startHidden"] as? Bool { startHidden = value }
        if let value = settings["maxHistorySize"] as? Int { maxHistorySize = value }
        if let value = settings["preserveFormatting"] as? Bool { preserveFormatting = value }
        if let value = settings["maxStorageSizeMB"] as? Int { maxStorageSizeMB = value }
        if let value = settings["theme"] as? String, let theme = Theme(rawValue: value) { self.theme = theme }
        if let value = settings["accentColor"] as? String { accentColor = value }
        if let value = settings["animationSpeed"] as? String, let speed = AnimationSpeed(rawValue: value) { animationSpeed = speed }
        if let value = settings["automaticallyCheckForUpdates"] as? Bool { automaticallyCheckForUpdates = value }
        if let value = settings["downloadUpdatesAutomatically"] as? Bool { downloadUpdatesAutomatically = value }
        if let value = settings["developerMode"] as? Bool { developerMode = value }
        if let value = settings["diagnosticLogging"] as? Bool { diagnosticLogging = value }
    }

    /// Resets all settings to their factory defaults.
    public func resetAllSettings() {
        launchAtLogin = true
        showDockIcon = false
        menuBarOnly = true
        notificationsEnabled = true
        startHidden = true
        maxHistorySize = 100
        preserveFormatting = true
        maxStorageSizeMB = 50
        theme = .blackGold
        accentColor = "#D4A017"
        animationSpeed = .normal
        automaticallyCheckForUpdates = true
        downloadUpdatesAutomatically = false
        developerMode = false
        diagnosticLogging = false
    }

    // MARK: - Errors

    public enum ImportError: LocalizedError {
        case invalidFormat

        public var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "The settings file has an invalid format."
            }
        }
    }
}

// MARK: - UserDefaults Convenience
// Uses the centralized extension defined in FoundationExtensions.swift
