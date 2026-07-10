// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Extensions on standard Foundation and AppKit types for convenience.
/// These provide helper methods used throughout the application.

// MARK: - String Extensions

extension String {
    /// Truncates a string to a maximum length, appending an ellipsis if trimmed.
    func truncated(to maxLength: Int, ellipsis: String = "...") -> String {
        if count <= maxLength { return self }
        let endIndex = index(startIndex, offsetBy: maxLength - ellipsis.count)
        return String(self[..<endIndex]) + ellipsis
    }

    /// Returns true if the string matches the given regex pattern.
    func matches(regex pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(location: 0, length: utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

// MARK: - Date Extensions

extension Date {
    /// Returns a human-readable "time ago" string.
    var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        switch interval {
        case ..<1:
            return "Just now"
        case ..<60:
            return "\(Int(interval))s ago"
        case ..<3600:
            return "\(Int(interval / 60))m ago"
        case ..<86400:
            return "\(Int(interval / 3600))h ago"
        case ..<604800:
            return "\(Int(interval / 86400))d ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }
}

// MARK: - Array Extensions

extension Array {
    /// Returns an array of unique elements based on a key path.
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

// MARK: - Data Extensions

extension Data {
    /// Attempts to decode this data as a UTF-8 string.
    var utf8String: String? {
        String(data: self, encoding: .utf8)
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// Returns the Boolean value for the given key. If not set, returns the default.
    /// This is the single canonical definition used throughout the app.
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil { return defaultValue }
        return bool(forKey: key)
    }

    /// Returns the String value for the given key. If not set, returns the default.
    func string(forKey key: String, defaultValue: String) -> String {
        string(forKey: key) ?? defaultValue
    }

    /// Returns the Integer value for the given key. If not set, returns the default.
    func integer(forKey key: String, defaultValue: Int) -> Int {
        if object(forKey: key) == nil { return defaultValue }
        return integer(forKey: key)
    }

    /// Checks if a value has been previously set for a given key.
    func hasValue(forKey key: String) -> Bool {
        object(forKey: key) != nil
    }
}

// MARK: - ProcessInfo Extensions

extension ProcessInfo {
    /// Returns true if the app is running in a debug configuration.
    var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
