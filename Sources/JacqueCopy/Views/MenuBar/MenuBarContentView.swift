// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// The main menu bar content view displayed when the user clicks the menu bar icon.
///
/// Provides quick access to both clipboards, recent history, pinned items,
/// search, settings, and other app functions.
/// macOS only - not available on Windows (system tray app).
#if os(macOS)
struct MenuBarContentView: View {

    // MARK: - Environment

    @EnvironmentObject var clipboardEngine: ClipboardEngine
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var shortcutManager: ShortcutManager

    // MARK: - State

    @State private var searchText: String = ""
    @State private var selectedTab: MenuTab = .recent
    @State private var showHistoryWindow: Bool = false
    @State private var pinnedExpanded: Bool = true

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header section
            headerSection

            Divider()
                .padding(.horizontal, 0)

            // Tab selector
            tabSelector

            Divider()
                .padding(.horizontal, 0)

            // Content based on selected tab
            contentSection

            Divider()

            // Footer with actions
            footerSection
        }
        .frame(width: 320)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .onReceive(NotificationCenter.default.publisher(for: .showHistoryWindow)) { _ in
            showHistoryWindow = true
        }
        .sheet(isPresented: $showHistoryWindow) {
            HistoryBrowserView()
                .environmentObject(clipboardEngine)
                .environmentObject(settings)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Jacque-Copy")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                // Clipboard status indicators
                HStack(spacing: 6) {
                    clipboardIndicator(label: "A", isActive: clipboardEngine.clipboardA != nil)
                    clipboardIndicator(label: "B", isActive: clipboardEngine.clipboardB != nil)
                }
            }

            // Current clipboard previews
            HStack(spacing: 12) {
                clipboardPreview(
                    label: "A",
                    shortcut: "⌘C/⌘V",
                    item: clipboardEngine.clipboardA,
                    isGold: false
                )

                clipboardPreview(
                    label: "B",
                    shortcut: shortcutManager.copyToClipboardBDescription,
                    item: clipboardEngine.clipboardB,
                    isGold: true
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(MenuTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12))
                        Text(tab.title)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .foregroundColor(selectedTab == tab ? Color(hex: "#D4A017") : .secondary)
                    .background(
                        selectedTab == tab
                            ? Color(hex: "#D4A017").opacity(0.1)
                            : Color.clear
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
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
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

            // Combined recent items from both clipboards
            let recentItems = getFilteredRecentItems()

            if recentItems.isEmpty {
                emptyState(message: "No clipboard history yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(recentItems.prefix(10)) { item in
                            ClipboardItemRow(item: item) {
                                clipboardEngine.setClipboardBContent(item)
                                clipboardEngine.pasteFromClipboardB()
                            }
                            .environmentObject(clipboardEngine)

                            if item.id != recentItems.prefix(10).last?.id {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 300)
            }
        }
    }

    // MARK: - Pinned Content

    private var pinnedContent: some View {
        let pinnedItems = clipboardEngine.getHistory(for: .system)
            .filter { $0.isPinned } +
            clipboardEngine.getHistory(for: .secondary)
            .filter { $0.isPinned }

        return Group {
            if pinnedItems.isEmpty {
                emptyState(message: "No pinned items.\nPin items from history to keep them here.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(pinnedItems) { item in
                            ClipboardItemRow(item: item) {
                                clipboardEngine.setClipboardBContent(item)
                                clipboardEngine.pasteFromClipboardB()
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
                .frame(maxHeight: 300)
            }
        }
    }

    // MARK: - Search Content

    private var searchContent: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText, placeholder: "Type to search...")
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

            let results = clipboardEngine.searchHistory(query: searchText)

            if searchText.isEmpty {
                emptyState(message: "Start typing to search")
            } else if results.isEmpty {
                emptyState(message: "No results found")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results.prefix(20)) { item in
                            ClipboardItemRow(item: item) {
                                clipboardEngine.setClipboardBContent(item)
                                clipboardEngine.pasteFromClipboardB()
                            }
                            .environmentObject(clipboardEngine)

                            if item.id != results.prefix(20).last?.id {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 300)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 0) {
            // History browser button
            footerButton(icon: "clock.arrow.circlepath", label: "History") {
                showHistoryWindow = true
            }

            Spacer()

            // Clear button
            footerButton(icon: "trash", label: "Clear B") {
                clipboardEngine.clearClipboardB()
            }
            .disabled(clipboardEngine.clipboardB == nil)

            Spacer()

            // Settings button
            footerButton(icon: "gearshape", label: "Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Spacer()

            // Quit button
            footerButton(icon: "power", label: "Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func getFilteredRecentItems() -> [ClipboardItem] {
        var items = clipboardEngine.getHistory(for: .system).prefix(5).map { ($0, ClipboardIdentifier.system) } +
            clipboardEngine.getHistory(for: .secondary).prefix(5).map { ($0, ClipboardIdentifier.secondary) }

        if !searchText.isEmpty {
            items = items.filter {
                $0.0.preview.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items
            .sorted { $0.0.capturedAt > $1.0.capturedAt }
            .map { $0.0 }
    }

    // MARK: - Subviews

    /// Clipboard indicator dot showing whether a clipboard has content.
    private func clipboardIndicator(label: String, isActive: Bool) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(isActive ? Color(hex: "#D4A017") : Color.secondary.opacity(0.4))
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    /// Preview card for a clipboard's current content.
    private func clipboardPreview(
        label: String,
        shortcut: String,
        item: ClipboardItem?,
        isGold: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Clipboard \(label)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isGold ? Color(hex: "#D4A017") : .secondary)
                Spacer()
                Text(shortcut)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Text(item?.preview ?? "Empty")
                .font(.system(size: 11))
                .foregroundColor(item != nil ? .primary : .secondary.opacity(0.5))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isGold
                        ? Color(hex: "#D4A017").opacity(0.08)
                        : Color.primary.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isGold
                                ? Color(hex: "#D4A017").opacity(0.3)
                                : Color.primary.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }

    /// Empty state placeholder.
    private func emptyState(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.4))

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
    }

    /// Menu bar footer button.
    private func footerButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 8))
            }
            .foregroundColor(.secondary)
            .frame(width: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Menu Tab

enum MenuTab: String, CaseIterable, Identifiable {
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

#endif // os(macOS)

// MARK: - Visual Effect Background

#if os(macOS)
/// AppKit NSVisualEffectView wrapper for SwiftUI.
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
#endif
