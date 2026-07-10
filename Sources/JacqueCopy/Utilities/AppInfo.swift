// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Provides information about application state for diagnostics and debugging.
public struct AppInfo {

    /// Application version from Info.plist.
    public static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    /// Build number from Info.plist.
    public static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    /// Full version string (version + build).
    public static var fullVersion: String {
        "\(version) (\(buildNumber))"
    }

    /// Bundle identifier.
    public static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.jacquecopy"
    }

    /// macOS version string.
    public static var macOSVersion: String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    }

    /// Hardware architecture.
    public static var architecture: String {
        #if arch(arm64)
        return "arm64 (Apple Silicon)"
        #elseif arch(x86_64)
        return "x86_64 (Intel)"
        #else
        return "Unknown"
        #endif
    }

    /// System information summary for diagnostics.
    public static var systemInfo: String {
        """
        Jacque-Copy v\(fullVersion)
        macOS \(macOSVersion)
        Architecture: \(architecture)
        Bundle ID: \(bundleIdentifier)
        """
    }
}
