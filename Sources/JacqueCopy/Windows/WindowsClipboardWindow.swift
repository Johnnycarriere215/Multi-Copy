// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

#if os(Windows)

import SwiftUI
import Win32Bridge

/// Windows clipboard history viewer window.
/// Provides the same dual-clipboard UI as the macOS MenuBarContentView,
/// adapted for a standalone window on Windows.
struct WindowsClipboardWindow: View {

    // MARK: - Environment

    @EnvironmentObject var clipboardEngine: ClipboardEngine
    @EnvironmentObject var settings: AppSettings

    // MARK: - State

    @State private var searchText: String = ""
    @State private var selectedTab: WindowTab = .recent

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header section with clipboard status
            headerSection

            Divider()
                .padding(.horizontal, 12)

            // Tab selector
            tabSelector

            Divider()
                .padding(.horizontal, 12)

            // Content based on selected tab
            contentSection

            Divider()

            // Footer with actions
            footerSection
        }
        .frame(minWidth: 380, idealWidth: 420, minHeight: 440, idealHeight: 520)
        .background(Color(white: 0.97))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            // Title row
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#D4A017"))

                Text("Jacque-Copy")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // Clipboard status indicators
                HStack(spacing: 8) {
                    clipboardStatusDot(label: "A", isActive: clipboardEngine.clipboardA != nil)
                    clipboardStatusDot(label: "B", isActive: clipboardEngine.clipboardB != nil)
                }
            }

            // Current clipboard previews
            HStack(spacing: 12) {
                clipboardPreviewCard(
                    label: "Clipboard A",
                    shortcut: "Ctrl+C / Ctrl+V",
                    item: clipboardEngine.clipboardA,
                    accentColor: Color.secondary
                )

                clipboardPreviewCard(
                    label: "Clipboard B",
                    shortcut: "Alt+C / Alt+V",
                    item: clipboardEngine.clipboardB,
                    accentColor: Color(hex: "#D4A017")
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(WindowTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(selectedTab == tab ? Color(hex: "#D4A017") : .secondary)
                    .background(
                        selectedTab == tab
                            ? Color(hex: "#D4A017").opacity(0.1)
                            : Color.clear
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        switch selectedTab {
        case .recent:
            recentContent
        case .pinned:
            pinnedContent
        case .search:
            searchContent
        }
    }

    // MARK: - Recent Content

    private var recentContent: some View {
        VStack(spacing: 0) {
            // Quick search bar
            SearchBar(text: $searchText, placeholder: "Search clipboard history...")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            let recentItems = getFilteredRecentItems()

            if recentItems.isEmpty {
                emptyState(message: "No clipboard history yet", icon: "clock")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(recentItems.prefix(15)) { item in
                            ClipboardItemRow(item: item) {
                                clipboardEngine.setClipboardBContent(item)
                            }
                            .environmentObject(clipboardEngine)

                            if item.id != recentItems.prefix(15).last?.id {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Pinned Content

    private var pinnedContent: some View {
        let pinnedItems = (clipboardEngine.getHistory(for: .system) +
                           clipboardEngine.getHistory(for: .secondary))
            .filter { $0.isPinned }

        return Group {
            if pinnedItems.isEmpty {
                emptyState(message: "No pinned items.\nPin items from history to keep them here.", icon: "pin")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(pinnedItems) { item in
                            ClipboardItemRow(item: item) {
                                clipboardEngine.setClipboardBContent(item)
                            }
                            .environmentObject(clipboardEngine)

                            if item.id != pinnedItems.last?.id {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Search Content

    private var searchContent: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText, placeholder: "Type to search...")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            let results = searchText.isEmpty
                ? [] : clipboardEngine.searchHistory(query: searchText)

            if searchText.isEmpty {
                emptyState(message: "Start typing to search", icon: "magnifyingglass")
            } else if results.isEmpty {
                emptyState(message: "No results found for \"\(searchText)\"", icon: "magnifyingglass")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results.prefix(25)) { item in
                            ClipboardItemRow(item: item) {
                                clipboardEngine.setClipboardBContent(item)
                            }
                            .environmentObject(clipboardEngine)

                            if item.id != results.prefix(25).last?.id {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 0) {
            // History count
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(clipboardEngine.totalHistoryCount) items")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Clear Clipboard B button
            Button {
                clipboardEngine.clearClipboardB()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                    Text("Clear B")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
            .disabled(clipboardEngine.clipboardB == nil)

            Spacer()

            // Swap clipboards button
            Button {
                clipboardEngine.swapClipboards()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 11))
                    Text("Swap")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
            .disabled(clipboardEngine.clipboardA == nil && clipboardEngine.clipboardB == nil)

            Spacer()

            // Hide to Tray button
            Button {
                win32_hide_app_window()
                win32_tray_notify_hidden()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 11))
                    Text("To Tray")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.08))
                )
            }
            .buttonStyle(.plain)

            Spacer()

            // Quit button
            Button {
                win32_window_cleanup()
                exit(0)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                        .font(.system(size: 11))
                    Text("Quit")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func getFilteredRecentItems() -> [ClipboardItem] {
        var items = clipboardEngine.getHistory(for: .system).prefix(10).map { $0 } +
            clipboardEngine.getHistory(for: .secondary).prefix(10).map { $0 }

        if !searchText.isEmpty {
            items = items.filter {
                $0.preview.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items
            .sorted { $0.capturedAt > $1.capturedAt }
            .uniqued(by: \.id)
    }

    // MARK: - Subviews

    /// Clipboard status indicator dot.
    private func clipboardStatusDot(label: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color(hex: "#D4A017") : Color.secondary.opacity(0.35))
                .frame(width: 7, height: 7)
            Text("Clipboard \(label)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    /// Preview card for a clipboard's current content.
    private func clipboardPreviewCard(
        label: String,
        shortcut: String,
        item: ClipboardItem?,
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(accentColor)
                Spacer()
                Text(shortcut)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Text(item?.preview ?? "Empty")
                .font(.system(size: 11))
                .foregroundColor(item != nil ? .primary : .secondary.opacity(0.45))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(accentColor.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor.opacity(0.25), lineWidth: 1)
                )
        )
    }

    /// Empty state placeholder.
    private func emptyState(message: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.35))

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Window Tab

enum WindowTab: String, CaseIterable, Identifiable {
    case recent
    case pinned
    case search

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent: return "Recent"
        case .pinned: return "Pinned"
        case .search: return "Search"
        }
    }

    var icon: String {
        switch self {
        case .recent: return "clock"
        case .pinned: return "pin"
        case .search: return "magnifyingglass"
        }
    }
}

#endif
