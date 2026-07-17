// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// Full clipboard history browser with search and click-to-copy.
///
/// Shows both clipboards' histories in a single scrollable list. Built
/// from the same view patterns as the menu bar view.
struct HistoryBrowserView: View {

    // MARK: - Environment

    @EnvironmentObject var clipboardEngine: ClipboardEngine
    @EnvironmentObject var settings: AppSettings

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var searchText: String = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
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

            Divider()

            // Search
            SearchBar(text: $searchText, placeholder: "Search history...")
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            // Content
            let items = filteredItems

            if items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text(searchText.isEmpty ? "No clipboard history" : "No results for \"\(searchText)\"")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(minWidth: 500, idealWidth: 600, minHeight: 400, idealHeight: 500)
    }

    // MARK: - Computed Properties

    private var totalItemCount: Int {
        clipboardEngine.getHistory(for: .system).count +
        clipboardEngine.getHistory(for: .secondary).count
    }

    private var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardEngine.getHistory(for: .system) +
                clipboardEngine.getHistory(for: .secondary)
        } else {
            return clipboardEngine.searchHistory(query: searchText)
        }
    }
}
