// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// Displays a single clipboard history item with preview, metadata,
/// and action buttons (pin, favorite, delete, paste).
struct ClipboardItemRow: View {

    // MARK: - Properties

    let item: ClipboardItem
    var onPaste: () -> Void

    @EnvironmentObject var clipboardEngine: ClipboardEngine

    // MARK: - State

    @State private var isHovering: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            // Content type icon
            contentTypeIcon
                .frame(width: 18)

            // Main content
            VStack(alignment: .leading, spacing: 2) {
                // Preview text
                Text(item.preview)
                    .font(.system(size: 12))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                // Metadata
                HStack(spacing: 6) {
                    // Time ago
                    Text(item.capturedAt, style: .relative)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)

                    // Source app
                    if let sourceApp = item.sourceApplication {
                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(sourceApp)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Size
                    if item.totalSize > 1024 {
                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(formatBytes(item.totalSize))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }

                // Tags
                if !item.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 8))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(hex: "#D4A017").opacity(0.15))
                                )
                                .foregroundColor(Color(hex: "#D4A017"))
                        }
                    }
                }
            }

            Spacer()

            // Action buttons (visible on hover)
            if isHovering {
                HStack(spacing: 4) {
                    // Pin button
                    Button {
                        clipboardEngine.togglePinned(item)
                    } label: {
                        Image(systemName: item.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 10))
                            .foregroundColor(item.isPinned ? Color(hex: "#D4A017") : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin" : "Pin")

                    // Favorite button
                    Button {
                        clipboardEngine.toggleFavorite(item)
                    } label: {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(item.isFavorite ? Color(hex: "#D4A017") : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(item.isFavorite ? "Remove from favorites" : "Add to favorites")

                    // Delete button
                    Button {
                        clipboardEngine.removeFromHistory(item)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Delete from history")

                    // Paste shortcut hint
                    Text("↩")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isHovering
                ? Color.primary.opacity(0.05)
                : Color.clear
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onPaste()
        }
        .contextMenu {
            Button("Paste to Clipboard B") {
                clipboardEngine.setClipboardBContent(item)
            }
            Button("Paste as System Clipboard") {
                PasteboardManager.shared.writeToPasteboard(item)
            }
            Divider()
            Button(item.isPinned ? "Unpin" : "Pin") {
                clipboardEngine.togglePinned(item)
            }
            Button(item.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                clipboardEngine.toggleFavorite(item)
            }
            Divider()
            #if os(macOS)
            Button("Copy Preview Text") {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(item.preview, forType: .string)
            }
            #else
            Button("Copy Preview Text") {
                let data = item.preview.data(using: .utf8) ?? Data()
                PlatformServices.clipboard.writeRepresentations(["public.utf8-plain-text": data])
            }
            #endif
            Divider()
            Button("Delete", role: .destructive) {
                clipboardEngine.removeFromHistory(item)
            }
        }
    }

    // MARK: - Content Type Icon

    @ViewBuilder
    private var contentTypeIcon: some View {
        switch item.contentType {
        case .plainText:
            Image(systemName: "text.alignleft")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        case .richText:
            Image(systemName: "text.word.spacing")
                .font(.system(size: 11))
                .foregroundColor(.blue)
        case .image:
            Image(systemName: "photo")
                .font(.system(size: 11))
                .foregroundColor(.green)
        case .file:
            Image(systemName: "doc")
                .font(.system(size: 11))
                .foregroundColor(.orange)
        case .url:
            Image(systemName: "link")
                .font(.system(size: 11))
                .foregroundColor(.purple)
        case .other:
            Image(systemName: "questionmark.square")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1_048_576 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / 1_048_576)
        }
    }
}
