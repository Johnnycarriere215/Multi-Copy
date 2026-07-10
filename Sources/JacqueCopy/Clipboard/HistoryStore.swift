// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Manages clipboard history persistence using Codable and JSON file storage.
///
/// Each clipboard (system and secondary) has its own independent history.
/// Items are stored as individual JSON files in separate directories for
/// efficient read/write operations and to avoid loading the entire history
/// into memory at once.
public final class HistoryStore {

    // MARK: - Singleton

    public static let shared = HistoryStore()

    // MARK: - Properties

    /// Directory for Clipboard A (system) history items.
    private let systemHistoryDirectory: URL

    /// Directory for Clipboard B (secondary) history items.
    private let secondaryHistoryDirectory: URL

    /// Maximum total storage size in bytes (default 50MB).
    private var maxStorageSize: Int64 {
        Int64(AppSettings.shared.maxStorageSizeMB) * 1_000_000
    }

    /// In-memory cache for fast access.
    private var systemHistoryCache: [ClipboardItem] = []
    private var secondaryHistoryCache: [ClipboardItem] = []
    private let cacheLock = NSLock()

    /// File manager for I/O operations.
    private let fileManager = FileManager.default

    /// JSON encoder configured for clipboard items.
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    /// JSON decoder configured for clipboard items.
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    private init() {
        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let baseDirectory = appSupport.appendingPathComponent("JacqueCopy/History")
        systemHistoryDirectory = baseDirectory.appendingPathComponent("ClipboardA")
        secondaryHistoryDirectory = baseDirectory.appendingPathComponent("ClipboardB")

        createDirectories()
        loadCache()
    }

    // MARK: - Directory Setup

    private func createDirectories() {
        try? fileManager.createDirectory(
            at: systemHistoryDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? fileManager.createDirectory(
            at: secondaryHistoryDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    // MARK: - Cache Loading

    private func loadCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        systemHistoryCache = loadItems(from: systemHistoryDirectory)
        secondaryHistoryCache = loadItems(from: secondaryHistoryDirectory)
    }

    private func loadItems(from directory: URL) -> [ClipboardItem] {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        let jsonFiles = files.filter { $0.pathExtension == "json" }

        let items = jsonFiles.compactMap { url -> ClipboardItem? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(ClipboardItem.self, from: data)
        }

        return items.sorted { $0.capturedAt > $1.capturedAt }
    }

    // MARK: - History Operations

    /// Adds a clipboard item to the specified clipboard's history.
    /// - Parameters:
    ///   - item: The item to add.
    ///   - clipboard: Whether to store in system or secondary history.
    public func addItem(_ item: ClipboardItem, to clipboard: ClipboardIdentifier) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        // Determine target directory and cache
        let directory: URL
        switch clipboard {
        case .system:
            // Avoid duplicates
            if let existingIndex = systemHistoryCache.firstIndex(where: {
                $0.representations == item.representations
            }) {
                systemHistoryCache.remove(at: existingIndex)
            }
            systemHistoryCache.insert(item, at: 0)
            directory = systemHistoryDirectory
        case .secondary:
            if let existingIndex = secondaryHistoryCache.firstIndex(where: {
                $0.representations == item.representations
            }) {
                secondaryHistoryCache.remove(at: existingIndex)
            }
            secondaryHistoryCache.insert(item, at: 0)
            directory = secondaryHistoryDirectory
        }

        // Persist to disk
        persistItem(item, to: directory)

        // Enforce history size limits
        enforceLimits(clipboard: clipboard)
    }

    /// Gets history items for a specific clipboard.
    public func getHistory(
        for clipboard: ClipboardIdentifier,
        includePinned: Bool = true
    ) -> [ClipboardItem] {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        let items: [ClipboardItem]
        switch clipboard {
        case .system:
            items = systemHistoryCache
        case .secondary:
            items = secondaryHistoryCache
        }

        if includePinned {
            return items
        }
        return items.filter { !$0.isPinned }
    }

    /// Searches history across both clipboards.
    public func search(query: String) -> [ClipboardItem] {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        let allItems = systemHistoryCache + secondaryHistoryCache
        let lowercasedQuery = query.lowercased()

        guard !lowercasedQuery.isEmpty else {
            return allItems.sorted { $0.capturedAt > $1.capturedAt }
        }

        return allItems.filter { item in
            item.preview.lowercased().contains(lowercasedQuery) ||
            item.tags.contains(where: { $0.lowercased().contains(lowercasedQuery) }) ||
            (item.sourceApplication?.lowercased().contains(lowercasedQuery) ?? false)
        }.sorted { $0.capturedAt > $1.capturedAt }
    }

    /// Toggles the pinned status of a history item.
    public func togglePinned(_ item: ClipboardItem) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        var updatedItem = item
        updatedItem.isPinned.toggle()

        updateItemInBothCaches(updatedItem)
        persistItemUpdate(updatedItem)
    }

    /// Toggles the favorite status of a history item.
    public func toggleFavorite(_ item: ClipboardItem) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        var updatedItem = item
        updatedItem.isFavorite.toggle()

        updateItemInBothCaches(updatedItem)
        persistItemUpdate(updatedItem)
    }

    /// Removes a specific item from history.
    public func removeItem(_ item: ClipboardItem) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        removeFromCache(item)
        removeFromDisk(item)
    }

    /// Clears all history for a specific clipboard.
    public func clearHistory(for clipboard: ClipboardIdentifier) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        let directory: URL
        switch clipboard {
        case .system:
            systemHistoryCache.removeAll()
            directory = systemHistoryDirectory
        case .secondary:
            secondaryHistoryCache.removeAll()
            directory = secondaryHistoryDirectory
        }

        // Remove all files in directory
        if let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    /// Clears all history across both clipboards.
    public func clearAllHistory() {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        systemHistoryCache.removeAll()
        secondaryHistoryCache.removeAll()

        for directory in [systemHistoryDirectory, secondaryHistoryDirectory] {
            if let files = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ) {
                for file in files {
                    try? fileManager.removeItem(at: file)
                }
            }
        }
    }

    /// Total number of items across both histories.
    public var totalCount: Int {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return systemHistoryCache.count + secondaryHistoryCache.count
    }

    // MARK: - Export/Import

    /// Exports all history to a JSON file.
    public func export(to url: URL) throws {
        cacheLock.lock()
        let allItems = systemHistoryCache + secondaryHistoryCache
        cacheLock.unlock()

        let data = try encoder.encode(allItems)
        try data.write(to: url)
    }

    /// Imports history from a JSON file.
    public func import_(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let items = try decoder.decode([ClipboardItem].self, from: data)

        cacheLock.lock()
        defer { cacheLock.unlock() }

        for item in items {
            // Distribute to appropriate cache based on content analysis
            // New imports default to system clipboard
            systemHistoryCache.append(item)
            persistItem(item, to: systemHistoryDirectory)
        }

        // Sort by capture date
        systemHistoryCache.sort { $0.capturedAt > $1.capturedAt }
        enforceLimits(clipboard: .system)
    }

    // MARK: - Private Helpers

    private func directory(for clipboard: ClipboardIdentifier) -> URL {
        switch clipboard {
        case .system: return systemHistoryDirectory
        case .secondary: return secondaryHistoryDirectory
        }
    }

    private func persistItem(_ item: ClipboardItem, to directory: URL) {
        let filename = "\(item.id.uuidString).json"
        let fileURL = directory.appendingPathComponent(filename)

        guard let data = try? encoder.encode(item) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func persistItemUpdate(_ item: ClipboardItem) {
        // Find which directory the item belongs to
        for directory in [systemHistoryDirectory, secondaryHistoryDirectory] {
            let fileURL = directory.appendingPathComponent("\(item.id.uuidString).json")
            if fileManager.fileExists(atPath: fileURL.path) {
                if let data = try? encoder.encode(item) {
                    try? data.write(to: fileURL, options: .atomic)
                }
                return
            }
        }
    }

    private func updateItemInBothCaches(_ updatedItem: ClipboardItem) {
        if let index = systemHistoryCache.firstIndex(where: { $0.id == updatedItem.id }) {
            systemHistoryCache[index] = updatedItem
        }
        if let index = secondaryHistoryCache.firstIndex(where: { $0.id == updatedItem.id }) {
            secondaryHistoryCache[index] = updatedItem
        }
    }

    private func removeFromCache(_ item: ClipboardItem) {
        systemHistoryCache.removeAll { $0.id == item.id }
        secondaryHistoryCache.removeAll { $0.id == item.id }
    }

    private func removeFromDisk(_ item: ClipboardItem) {
        for directory in [systemHistoryDirectory, secondaryHistoryDirectory] {
            let fileURL = directory.appendingPathComponent("\(item.id.uuidString).json")
            try? fileManager.removeItem(at: fileURL)
        }
    }

    private func enforceLimits(clipboard: ClipboardIdentifier) {
        let cache: [ClipboardItem]
        let directory: URL

        switch clipboard {
        case .system:
            cache = systemHistoryCache
            directory = systemHistoryDirectory
        case .secondary:
            cache = secondaryHistoryCache
            directory = secondaryHistoryDirectory
        }

        // Separate pinned items (never removed)
        let pinnedItems = cache.filter { $0.isPinned }
        var unpinnedItems = cache.filter { !$0.isPinned }

        // Read current max history size from settings (not cached)
        let maxSize = UserDefaults.standard.integer(forKey: "maxHistorySize", defaultValue: 100)

        // Enforce count limit
        if unpinnedItems.count > maxSize {
            let itemsToRemove = unpinnedItems.suffix(unpinnedItems.count - maxSize)
            for item in itemsToRemove {
                let fileURL = directory.appendingPathComponent("\(item.id.uuidString).json")
                try? fileManager.removeItem(at: fileURL)
            }
            unpinnedItems = Array(unpinnedItems.prefix(maxSize))
        }

        // Enforce storage size limit
        let totalSize: Int64 = Int64(
            (pinnedItems + unpinnedItems).reduce(0) { $0 + $1.totalSize }
        )
        if totalSize > maxStorageSize {
            var currentSize = totalSize
            for item in unpinnedItems.reversed() {
                if currentSize <= maxStorageSize { break }
                let fileURL = directory.appendingPathComponent("\(item.id.uuidString).json")
                try? fileManager.removeItem(at: fileURL)
                currentSize -= Int64(item.totalSize)
            }
        }

        // Update cache
        let updatedCache = pinnedItems + unpinnedItems
        switch clipboard {
        case .system:
            systemHistoryCache = updatedCache.sorted { $0.capturedAt > $1.capturedAt }
        case .secondary:
            secondaryHistoryCache = updatedCache.sorted { $0.capturedAt > $1.capturedAt }
        }
    }
}
