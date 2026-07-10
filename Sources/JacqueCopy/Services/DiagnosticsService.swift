// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Centralized diagnostic logging for development and troubleshooting.
///
/// When diagnostic logging is enabled (via Settings > Advanced),
/// all significant operations are logged with timestamps and metadata.
public final class DiagnosticsService: ObservableObject {

    // MARK: - Singleton

    public static let shared = DiagnosticsService()

    // MARK: - Published Properties

    /// Whether diagnostic logging is currently enabled.
    @Published public var isLogging: Bool {
        didSet {
            UserDefaults.standard.set(isLogging, forKey: "diagnosticLogging")
        }
    }

    /// Recent log entries for display in the diagnostics view.
    @Published public private(set) var recentLogs: [LogEntry] = []

    // MARK: - Properties

    /// Maximum number of in-memory log entries.
    private let maxLogEntries: Int = 1000

    /// File URL for persistent log storage.
    private let logFileURL: URL

    /// Queue for thread-safe log writing.
    private let logQueue = DispatchQueue(label: "com.jacquecopy.diagnostics", qos: .utility)

    /// Date formatter for log timestamps.
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Initialization

    private init() {
        self.isLogging = UserDefaults.standard.bool(forKey: "diagnosticLogging", defaultValue: false)

        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let logsDirectory = appSupport.appendingPathComponent("JacqueCopy/Logs")
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        let dateString = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        self.logFileURL = logsDirectory.appendingPathComponent("jacque-copy-\(dateString).log")
    }

    // MARK: - Logging Methods

    /// Logs an informational message.
    public func info(_ message: String, category: String = "General") {
        log(level: .info, message: message, category: category)
    }

    /// Logs a warning message.
    public func warning(_ message: String, category: String = "General") {
        log(level: .warning, message: message, category: category)
    }

    /// Logs an error message.
    public func error(_ message: String, category: String = "General") {
        log(level: .error, message: message, category: category)
    }

    /// Logs a debug message (only when developer mode is enabled).
    public func debug(_ message: String, category: String = "Debug") {
        guard AppSettings.shared.developerMode else { return }
        log(level: .debug, message: message, category: category)
    }

    /// Logs a clipboard operation.
    public func logClipboardOperation(
        action: String,
        clipboard: ClipboardIdentifier,
        itemType: String
    ) {
        log(
            level: .info,
            message: "\(action): Clipboard \(clipboard.shortName) - \(itemType)",
            category: "Clipboard"
        )
    }

    // MARK: - Log Management

    /// Returns all log files sorted by date.
    public func getLogFiles() -> [URL] {
        let logsDirectory = logFileURL.deletingLastPathComponent()
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        return files
            .filter { $0.pathExtension == "log" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
    }

    /// Clears all log files.
    public func clearAllLogs() {
        for fileURL in getLogFiles() {
            try? FileManager.default.removeItem(at: fileURL)
        }
        recentLogs.removeAll()
    }

    /// Exports logs to a specified URL.
    public func exportLogs(to url: URL) throws {
        var allLogs = ""
        for logFile in getLogFiles() {
            if let content = try? String(contentsOf: logFile, encoding: .utf8) {
                allLogs += content + "\n"
            }
        }
        try allLogs.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Private Methods

    private func log(level: LogLevel, message: String, category: String) {
        guard isLogging || level == .error else { return }

        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message
        )

        logQueue.async { [weak self] in
            guard let self = self else { return }

            // Add to in-memory buffer
            DispatchQueue.main.async {
                self.recentLogs.append(entry)
                if self.recentLogs.count > self.maxLogEntries {
                    self.recentLogs.removeFirst(self.recentLogs.count - self.maxLogEntries)
                }
            }

            // Write to file
            let logLine = "[\(self.dateFormatter.string(from: entry.timestamp))] "
                + "[\(entry.level.rawValue.uppercased())] "
                + "[\(entry.category)] "
                + "\(entry.message)\n"

            if let data = logLine.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                    if let handle = try? FileHandle(forWritingTo: self.logFileURL) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        try? handle.close()
                    }
                } else {
                    try? data.write(to: self.logFileURL, options: .atomic)
                }
            }
        }
    }
}

// MARK: - Supporting Types

/// Severity level for log entries.
public enum LogLevel: String, Codable, CaseIterable {
    case debug
    case info
    case warning
    case error

    var iconName: String {
        switch self {
        case .debug: return "ladybug"
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.octagon"
        }
    }
}

/// A single log entry with metadata.
public struct LogEntry: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let category: String
    public let message: String

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        level: LogLevel,
        category: String,
        message: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
    }
}
