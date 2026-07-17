// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// Full clipboard history browser with search, filtering, and keyboard navigation.
///
/// Provides a comprehensive view of both clipboards' histories with
/// instant search, keyboard shortcuts, and drag-to-reorder.
struct HistoryBrowserView: View {

    // MARK: - Environment

    @EnvironmentObject var clipboardEngine: ClipboardEngine
    @EnvironmentObject var settings: AppSettings

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var searchText: String = ""
    @State private var filterClipboard: ClipboardIdentifier?
    @State private var sortOrder: SortOrder = .newestFirst
    @State private var showOnlyPinned: Bool = false
    @State private var showOnlyFavorites: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Toolbar
            toolbarView

            Divider()

            // Content
            contentView
        }
        .frame(minWidth: 500, idealWidth: 600, minHeight: 400, idealHeight: 500)
        .background(
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#D4A017"))

            Text("Clipboard History")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            Text("\(totalItemCount) items")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack(spacing: 12) {
            // Search
            SearchBar(text: $searchText, placeholder: "Search history...")
                .frame(width: 200)

            Spacer()

            // Filter by clipboard
            Picker("Clipboard", selection: $filterClipboard) {
                Text("All").tag(nil as ClipboardIdentifier?)
                Text("Clipboard A").tag(ClipboardIdentifier.system as ClipboardIdentifier?)
                Text("Clipboard B").tag(ClipboardIdentifier.secondary as ClipboardIdentifier?)
            }
            .pickerStyle(.segmented)
            .frame(width: 220)

            // Pinned filter toggle
            Button {
                showOnlyPinned.toggle()
                if showOnlyPinned { showOnlyFavorites = false }
            } label: {
                Image(systemName: showOnlyPinned ? "pin.fill" : "pin")
                    .foregroundColor(showOnlyPinned ? Color(hex: "#D4A017") : .secondary)
            }
            .buttonStyle(.plain)
            .help("Show pinned items only")

            // Favorites filter toggle
            Button {
                showOnlyFavorites.toggle()
                if showOnlyFavorites { showOnlyPinned = false }
            } label: {
                Image(systemName: showOnlyFavorites ? "star.fill" : "star")
                    .foregroundColor(showOnlyFavorites ? Color(hex: "#D4A017") : .secondary)
            }
            .buttonStyle(.plain)
            .help("Show favorites only")

            // Sort order
            Menu {
                ForEach(SortOrder.allCases) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        HStack {
                            Text(order.displayName)
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)

            // Clear button
            Button {
                if let filter = filterClipboard {
                    clipboardEngine.clearHistory(for: filter)
                } else {
                    clipboardEngine.clearAllHistory()
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear displayed history")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Content

    private var contentView: some View {
        let items = filteredItems

        return Group {
            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            ClipboardItemRow(item: item) {
                                clipboardEngine.setClipboardBContent(item)
                                clipboardEngine.pasteFromClipboardB()
                            }
                            .environmentObject(clipboardEngine)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))

            Text(searchText.isEmpty ? "No clipboard history" : "No results for \"\(searchText)\"")
                .font(.body)
                .foregroundColor(.secondary)

            if !searchText.isEmpty {
                Button("Clear Search") {
                    searchText = ""
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    private var totalItemCount: Int {
        clipboardEngine.getHistory(for: .system).count +
        clipboardEngine.getHistory(for: .secondary).count
    }

    private var filteredItems: [ClipboardItem] {
        var items: [ClipboardItem] = []

        // Get items from appropriate clipboard(s)
        switch filterClipboard {
        case .none:
            items = clipboardEngine.getHistory(for: .system) +
                clipboardEngine.getHistory(for: .secondary)
        case .system:
            items = clipboardEngine.getHistory(for: .system)
        case .secondary:
            items = clipboardEngine.getHistory(for: .secondary)
        }

        // Apply search filter
        if !searchText.isEmpty {
            items = clipboardEngine.searchHistory(query: searchText)
        }

        // Apply pin/favorite filters
        if showOnlyPinned {
            items = items.filter { $0.isPinned }
        }
        if showOnlyFavorites {
            items = items.filter { $0.isFavorite }
        }

        // Sort
        switch sortOrder {
        case .newestFirst:
            items.sort { $0.capturedAt > $1.capturedAt }
        case .oldestFirst:
            items.sort { $0.capturedAt < $1.capturedAt }
        case .alphabetical:
            items.sort { $0.preview.localizedCaseInsensitiveCompare($1.preview) == .orderedAscending }
        case .bySize:
            items.sort { $0.totalSize > $1.totalSize }
        }

        return items
    }

    // MARK: - Sort Order

    enum SortOrder: String, CaseIterable, Identifiable {
        case newestFirst
        case oldestFirst
        case alphabetical
        case bySize

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .newestFirst: return "Newest First"
            case .oldestFirst: return "Oldest First"
            case .alphabetical: return "Alphabetical"
            case .bySize: return "By Size"
            }
        }
    }
}

