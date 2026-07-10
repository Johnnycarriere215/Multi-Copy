// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
#if os(macOS)
import AppKit
#endif

/// Represents a single clipboard item with all available pasteboard representations preserved.
///
/// Unlike simple string-based clipboard managers, ClipboardItem stores every
/// available NSPasteboard type so that rich content can be restored exactly
/// as it was originally copied.
public struct ClipboardItem: Identifiable, Codable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier for this clipboard item.
    public let id: UUID

    /// Human-readable preview text for display in history lists.
    public let preview: String

    /// The date and time this item was captured.
    public let capturedAt: Date

    /// The application bundle identifier that was the source of this content, if known.
    public let sourceApplication: String?

    /// All pasteboard type representations stored as raw data.
    /// Key: UTI string (e.g., "public.utf8-plain-text")
    /// Value: Raw binary data for that representation.
    public let representations: [String: Data]

    /// Whether this item is pinned and should not be removed from history.
    public var isPinned: Bool

    /// Whether this item is marked as a favorite.
    public var isFavorite: Bool

    /// User-assigned tags for organizational purposes.
    public var tags: [String]

    /// The size of all representations combined, in bytes.
    public var totalSize: Int {
        representations.values.reduce(0) { $0 + $1.count }
    }

    /// The dominant content type for display purposes.
    public var contentType: ContentType {
        let types = Set(representations.keys)

        if types.contains(where: { $0.contains("file-url") || $0.contains("file-ref") }) {
            return .file
        }
        if types.contains(where: { $0.contains("image") || $0.contains("tiff") || $0.contains("png") }) {
            return .image
        }
        if types.contains(where: { $0.contains("rtf") || $0.contains("html") || $0.contains("rtfd") }) {
            return .richText
        }
        if types.contains(where: { $0.contains("url") || $0.contains("link") }) {
            return .url
        }
        return .plainText
    }

    // MARK: - Content Type Enum

    public enum ContentType: String, Codable, CaseIterable {
        case plainText
        case richText
        case image
        case file
        case url
        case other
    }

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        preview: String,
        capturedAt: Date = Date(),
        sourceApplication: String? = nil,
        representations: [String: Data] = [:],
        isPinned: Bool = false,
        isFavorite: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.preview = preview
        self.capturedAt = capturedAt
        self.sourceApplication = sourceApplication
        self.representations = representations
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.tags = tags
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, preview, capturedAt, sourceApplication, representations
        case isPinned, isFavorite, tags
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Convenience Accessors

    /// Returns the plain text representation, if available.
    public var plainText: String? {
        guard let data = representations["public.utf8-plain-text"] ??
                representations["CF_TEXT"] ??
                representations["CF_UNICODETEXT"] else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Returns the RTF representation, if available.
    public var rtfData: Data? {
        #if os(macOS)
        return representations[NSPasteboard.PasteboardType.rtf.rawValue]
        #else
        return representations["public.rtf"] ?? representations["Rich Text Format"]
        #endif
    }

    /// Returns the HTML representation, if available.
    public var htmlString: String? {
        #if os(macOS)
        guard let data = representations[NSPasteboard.PasteboardType.html.rawValue] else { return nil }
        #else
        guard let data = representations["public.html"] ?? representations["HTML Format"] else { return nil }
        #endif
        return String(data: data, encoding: .utf8)
    }

    /// Returns the TIFF representation, if available.
    public var tiffData: Data? {
        #if os(macOS)
        return representations[NSPasteboard.PasteboardType.tiff.rawValue]
        #else
        return representations["CF_TIFF"] ?? representations["public.tiff"]
        #endif
    }

    /// Returns the PNG representation, if available.
    public var pngData: Data? {
        #if os(macOS)
        return representations[NSPasteboard.PasteboardType.png.rawValue]
        #else
        return representations["public.png"] ?? representations["PNG"]
        #endif
    }

    /// Returns the file URL if this item represents a file/folder reference.
    public var fileURL: URL? {
        #if os(macOS)
        if let data = representations[NSPasteboard.PasteboardType.fileURL.rawValue],
           let url = URL(dataRepresentation: data, relativeTo: nil) {
            return url
        }
        #else
        if let data = representations["CF_HDROP"],
           let urlString = String(data: data, encoding: .utf8) {
            return URL(fileURLWithPath: urlString)
        }
        #endif
        return nil
    }

    /// Generates a smart preview string based on available representations.
    public static func generatePreview(from representations: [String: Data]) -> String {
        // Try plain text first
        let textKey = "public.utf8-plain-text"
        if let textData = representations[textKey] ?? representations["CF_TEXT"] ?? representations["CF_UNICODETEXT"],
           let text = String(data: textData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            let preview = text.replacingOccurrences(of: "\n", with: " ")
            return String(preview.prefix(200))
        }

        // Try RTF
        #if os(macOS)
        if let rtfData = representations[NSPasteboard.PasteboardType.rtf.rawValue],
           let attributed = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
            let preview = attributed.string.replacingOccurrences(of: "\n", with: " ")
            return String(preview.prefix(200))
        }
        #else
        if let rtfData = representations["public.rtf"] ?? representations["Rich Text Format"],
           let text = String(data: rtfData, encoding: .utf8) {
            // Simple RTF text extraction for Windows
            let stripped = text.replacingOccurrences(of: "\\[a-z]+", with: "", options: .regularExpression)
                .replacingOccurrences(of: "{", with: "")
                .replacingOccurrences(of: "}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return String(stripped.prefix(200))
        }
        #endif

        // Try file URL
        #if os(macOS)
        if let data = representations[NSPasteboard.PasteboardType.fileURL.rawValue],
           let url = URL(dataRepresentation: data, relativeTo: nil) {
            return url.lastPathComponent
        }
        #else
        if let data = representations["CF_HDROP"],
           let path = String(data: data, encoding: .utf8) {
            let url = URL(fileURLWithPath: path)
            return url.lastPathComponent
        }
        #endif

        // Try image
        #if os(macOS)
        if representations[NSPasteboard.PasteboardType.tiff.rawValue] != nil ||
            representations[NSPasteboard.PasteboardType.png.rawValue] != nil {
            if let tiffData = representations[NSPasteboard.PasteboardType.tiff.rawValue],
               let image = NSImage(data: tiffData) {
                return "Image (\(Int(image.size.width))x\(Int(image.size.height)))"
            }
            return "Image"
        }
        #else
        if representations["CF_TIFF"] != nil || representations["CF_DIB"] != nil || representations["CF_BITMAP"] != nil {
            if let _ = representations["CF_DIB"] {
                return "Image (Bitmap)"
            }
            return "Image"
        }
        #endif

        // Try HTML
        #if os(macOS)
        let htmlKey = NSPasteboard.PasteboardType.html.rawValue
        #else
        let htmlKey = "HTML Format"
        #endif
        if let htmlData = representations[htmlKey] ?? representations["public.html"],
           let html = String(data: htmlData, encoding: .utf8) {
            let stripped = html.replacingOccurrences(
                of: "<[^>]+>",
                with: "",
                options: .regularExpression
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            return String(stripped.prefix(200))
        }

        // Fallback: list available types
        let typeCount = representations.count
        return "Item (\(typeCount) type\(typeCount == 1 ? "" : "s"))"
    }
}
