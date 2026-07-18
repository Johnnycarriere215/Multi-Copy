// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Represents the two independent clipboards managed by Jacque-Copy.
public enum ClipboardIdentifier: String, Codable, CaseIterable {
    case system
    case secondary

    public var displayName: String {
        switch self {
        case .system: return "Clipboard A"
        case .secondary: return "Clipboard B"
        }
    }

    public var shortName: String {
        switch self {
        case .system: return "A"
        case .secondary: return "B"
        }
    }

    public var defaultShortcut: String {
        switch self {
        case .system: return "⌘C / ⌘V"
        case .secondary: return "⌃C / ⌃V"
        }
    }
}

/// Core clipboard engine managing dual independent clipboards and their history.
///
/// This is the central coordinator. It uses platform-specific providers
/// (PasteboardManager on macOS, WindowsClipboardProvider on Windows)
/// to access the system clipboard. This engine is the source of truth
/// for the current state of both clipboards and their history.
@MainActor
public final class ClipboardEngine: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var clipboardA: ClipboardItem?
    @Published public private(set) var clipboardB: ClipboardItem?
    @Published public private(set) var isMonitoring: Bool = false
    @Published public private(set) var totalHistoryCount: Int = 0

    // MARK: - Dependencies

    private let clipboardProvider: ClipboardProvider
    private let historyStore: HistoryStore
    private var monitoringTimer: Timer?

    // MARK: - Singleton

    public static let shared = ClipboardEngine(
        clipboardProvider: PlatformServices.clipboard,
        historyStore: HistoryStore.shared
    )

    // MARK: - Initialization

    public init(clipboardProvider: ClipboardProvider, historyStore: HistoryStore) {
        self.clipboardProvider = clipboardProvider
        self.historyStore = historyStore
    }

    // MARK: - Public Operations

    /// Sets Clipboard B's content from an item (e.g., selected from history).
    /// Safe to call from any thread — state mutations are dispatched to main actor.
    public func setClipboardBContent(_ item: ClipboardItem) {
        clipboardB = item
        historyStore.addItem(item, to: .secondary)
        updateHistoryCount()
    }

    /// Writes Clipboard B's current content to the system pasteboard so it can
    /// be pasted into the frontmost application. No-op when Clipboard B is empty.
    public func pasteFromClipboardB() {
        guard let item = clipboardB else { return }
        clipboardProvider.writeRepresentations(item.representations)
    }

    /// Swaps the contents of Clipboard A and Clipboard B.
    public func swapClipboards() {
        let tempA = clipboardA
        clipboardA = clipboardB
        clipboardB = tempA

        if let newA = clipboardA {
            clipboardProvider.writeRepresentations(newA.representations)
        }
    }

    /// Clears the contents of Clipboard B.
    public func clearClipboardB() {
        clipboardB = nil
    }

    /// Captures the current system clipboard into Clipboard A's history.
    public func captureSystemClipboardChange() {
        guard let item = buildClipboardItemFromProvider() else { return }

        if let currentA = clipboardA, currentA.representations == item.representations {
            return
        }

        clipboardA = item
        historyStore.addItem(item, to: .system)
        updateHistoryCount()
    }

    /// Updates Clipboard A from the current system clipboard state.
    public func updateClipboardAFromSystem() {
        guard let item = buildClipboardItemFromProvider() else { return }

        clipboardA = item
        historyStore.addItem(item, to: .system)
        updateHistoryCount()
    }

    /// Helper to build a ClipboardItem from the current clipboard provider state.
    private func buildClipboardItemFromProvider() -> ClipboardItem? {
        let representations = clipboardProvider.captureCurrent()
        guard !representations.isEmpty else { return nil }

        let preview = ClipboardItem.generatePreview(from: representations)
        let sourceApp = clipboardProvider.frontmostApplicationBundleID()

        return ClipboardItem(
            id: UUID(),
            preview: preview,
            capturedAt: Date(),
            sourceApplication: sourceApp,
            representations: representations
        )
    }

    // MARK: - Monitoring

    /// Starts monitoring the system clipboard for Clipboard A changes.
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isMonitoring else { return }

            if self.clipboardProvider.hasChanged() {
                Task { @MainActor in
                    self.captureSystemClipboardChange()
                }
            }
        }

        if let timer = monitoringTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    /// Stops monitoring the system pasteboard.
    public func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    // MARK: - History Access

    public func getHistory(for clipboard: ClipboardIdentifier, includePinned: Bool = true) -> [ClipboardItem] {
        historyStore.getHistory(for: clipboard, includePinned: includePinned)
    }

    public func searchHistory(query: String) -> [ClipboardItem] {
        historyStore.search(query: query)
    }

    public func togglePinned(_ item: ClipboardItem) {
        historyStore.togglePinned(item)
    }

    public func toggleFavorite(_ item: ClipboardItem) {
        historyStore.toggleFavorite(item)
    }

    public func removeFromHistory(_ item: ClipboardItem) {
        historyStore.removeItem(item)
    }

    public func clearHistory(for clipboard: ClipboardIdentifier) {
        historyStore.clearHistory(for: clipboard)
        updateHistoryCount()
    }

    public func clearAllHistory() {
        historyStore.clearAllHistory()
        updateHistoryCount()
    }

    public func exportHistory(to url: URL) throws {
        try historyStore.export(to: url)
    }

    public func importHistory(from url: URL) throws {
        try historyStore.import_(from: url)
        updateHistoryCount()
    }

    // MARK: - Private Helpers

    private func updateHistoryCount() {
        totalHistoryCount = historyStore.totalCount
    }
}
