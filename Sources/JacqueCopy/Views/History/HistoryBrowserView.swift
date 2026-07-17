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
    @State private var selectedItemId: UUID?
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

    @ViewBuilder
    private var contentView: some View {
        let items = filteredItems

        if items.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                List(selection: $selectedItemId) {
                    ForEach(items) { item in
                        HistoryBrowserRow(
                            item: item,
                            onPaste: {
                                clipboardEngine.setClipboardBContent(item)
                                clipboardEngine.pasteFromClipboardB()
                            },
                            onSetClipboardA: {
                                PasteboardManager.shared.writeToPasteboard(item)
                            }
                        )
                        .environmentObject(clipboardEngine)
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .onChange(of: searchText) { _ in
                    if let first = items.first {
                        proxy.scrollTo(first.id, anchor: .top)
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

// MARK: - History Browser Row

struct HistoryBrowserRow: View {
    let item: ClipboardItem
    var onPaste: () -> Void
    var onSetClipboardA: () -> Void

    @EnvironmentObject var clipboardEngine: ClipboardEngine

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Content type icon
            contentIcon

            // Content preview
            VStack(alignment: .leading, spacing: 3) {
                Text(item.preview)
                    .font(.system(size: 12))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(item.capturedAt, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    if let source = item.sourceApplication {
                        Text(bundleName(for: source))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Text(item.contentType.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isHovering {
                HStack(spacing: 6) {
                    Button("Paste B") { onPaste() }
                        .font(.system(size: 10))
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#D4A017"))
                        .controlSize(.small)

                    Button("Set A") { onSetClipboardA() }
                        .font(.system(size: 10))
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture(count: 2) {
            onPaste()
        }
        .contextMenu {
            Button("Paste to Clipboard B") { onPaste() }
            Button("Set as Clipboard A") { onSetClipboardA() }
            Divider()
            Button(item.isPinned ? "Unpin" : "Pin") {
                clipboardEngine.togglePinned(item)
            }
            Button(item.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                clipboardEngine.toggleFavorite(item)
            }
            Divider()
            Button("Delete", role: .destructive) {
                clipboardEngine.removeFromHistory(item)
            }
        }
    }

    private var contentIcon: some View {
        Group {
            switch item.contentType {
            case .plainText:
                Image(systemName: "text.alignleft")
                    .foregroundColor(.secondary)
            case .richText:
                Image(systemName: "text.word.spacing")
                    .foregroundColor(.blue)
            case .image:
                Image(systemName: "photo")
                    .foregroundColor(.green)
            case .file:
                Image(systemName: "doc")
                    .foregroundColor(.orange)
            case .url:
                Image(systemName: "link")
                    .foregroundColor(.purple)
            case .other:
                Image(systemName: "questionmark.square")
                    .foregroundColor(.secondary)
            }
        }
        .font(.system(size: 12))
        .frame(width: 20)
    }

    private func bundleName(for identifier: String) -> String {
        let commonBundles: [String: String] = [
            "com.apple.Safari": "Safari",
            "com.apple.mail": "Mail",
            "com.apple.Notes": "Notes",
            "com.apple.TextEdit": "TextEdit",
            "com.apple.Xcode": "Xcode",
            "com.google.Chrome": "Chrome",
            "com.microsoft.VSCode": "VS Code",
            "org.mozilla.firefox": "Firefox",
            "com.apple.finder": "Finder",
            "com.apple.Pages": "Pages",
            "com.apple.Numbers": "Numbers",
            "com.apple.Keynote": "Keynote",
            "com.tinyspeck.slackmacgap": "Slack"
        ]
        return commonBundles[identifier] ?? identifier
            .replacingOccurrences(of: "com.", with: "")
            .replacingOccurrences(of: "org.", with: "")
    }
}
