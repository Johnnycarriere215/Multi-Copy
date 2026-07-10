// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Logger utility that wraps DiagnosticsService for convenient use throughout the app.
///
/// Provides static methods for logging at different levels without requiring
/// explicit access to the DiagnosticsService singleton.
public enum Logger {

    /// Logs an informational message.
    public static func info(_ message: String, category: String = "General") {
        DiagnosticsService.shared.info(message, category: category)
    }

    /// Logs a warning message.
    public static func warning(_ message: String, category: String = "General") {
        DiagnosticsService.shared.warning(message, category: category)
    }

    /// Logs an error message.
    public static func error(_ message: String, category: String = "General") {
        DiagnosticsService.shared.error(message, category: category)
    }

    /// Logs a debug message (only in debug builds or when developer mode enabled).
    public static func debug(_ message: String, category: String = "Debug") {
        DiagnosticsService.shared.debug(message, category: category)
    }
}
