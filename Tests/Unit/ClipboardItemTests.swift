// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import XCTest
@testable import JacqueCopy

final class ClipboardItemTests: XCTestCase {

    // MARK: - Initialization Tests

    func testClipboardItemInitialization() {
        let item = ClipboardItem(
            preview: "Hello, World!",
            sourceApplication: "com.apple.TextEdit",
            representations: ["public.utf8-plain-text": "Hello, World!".data(using: .utf8)!]
        )

        XCTAssertEqual(item.preview, "Hello, World!")
        XCTAssertEqual(item.sourceApplication, "com.apple.TextEdit")
        XCTAssertFalse(item.isPinned)
        XCTAssertFalse(item.isFavorite)
        XCTAssertTrue(item.tags.isEmpty)
    }

    func testClipboardItemDefaults() {
        let item = ClipboardItem(preview: "Test", representations: [:])

        XCTAssertNotNil(item.id)
        XCTAssertFalse(item.isPinned)
        XCTAssertFalse(item.isFavorite)
        XCTAssertEqual(item.capturedAt.timeIntervalSinceNow, 0, accuracy: 1.0)
    }

    // MARK: - Content Type Detection

    func testContentTypePlainText() {
        let item = ClipboardItem(
            preview: "Plain text",
            representations: ["public.utf8-plain-text": Data()]
        )
        XCTAssertEqual(item.contentType, .plainText)
    }

    func testContentTypeRichText() {
        let item = ClipboardItem(
            preview: "Rich text",
            representations: ["public.rtf": Data()]
        )
        XCTAssertEqual(item.contentType, .richText)
    }

    func testContentTypeImage() {
        let item = ClipboardItem(
            preview: "Image",
            representations: ["public.tiff": Data()]
        )
        XCTAssertEqual(item.contentType, .image)
    }

    func testContentTypeFile() {
        let item = ClipboardItem(
            preview: "File",
            representations: ["public.file-url": Data()]
        )
        XCTAssertEqual(item.contentType, .file)
    }

    // MARK: - Preview Generation

    func testGeneratePreviewFromPlainText() {
        let representations = ["public.utf8-plain-text": "Sample text content".data(using: .utf8)!]
        let preview = ClipboardItem.generatePreview(from: representations)
        XCTAssertEqual(preview, "Sample text content")
    }

    func testGeneratePreviewTruncation() {
        let longText = String(repeating: "a", count: 300)
        let representations = ["public.utf8-plain-text": longText.data(using: .utf8)!]
        let preview = ClipboardItem.generatePreview(from: representations)
        XCTAssertLessThanOrEqual(preview.count, 200)
    }

    func testGeneratePreviewFromImage() {
        let representations = ["public.tiff": Data([0x00, 0x01, 0x02])]
        let preview = ClipboardItem.generatePreview(from: representations)
        XCTAssertTrue(preview.contains("Image"))
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        let original = ClipboardItem(
            id: UUID(),
            preview: "Test content",
            capturedAt: Date(),
            sourceApplication: "com.apple.finder",
            representations: [
                "public.utf8-plain-text": "Test content".data(using: .utf8)!,
                "public.rtf": Data([0x01, 0x02])
            ],
            isPinned: true,
            isFavorite: true,
            tags: ["important", "work"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ClipboardItem.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.preview, decoded.preview)
        XCTAssertEqual(original.isPinned, decoded.isPinned)
        XCTAssertEqual(original.isFavorite, decoded.isFavorite)
        XCTAssertEqual(original.tags, decoded.tags)
    }

    // MARK: - Equatable

    func testEquality() {
        let id = UUID()
        let item1 = ClipboardItem(id: id, preview: "A", representations: [:])
        let item2 = ClipboardItem(id: id, preview: "B", representations: [:])

        XCTAssertEqual(item1, item2) // Same ID means same item
    }

    func testInequality() {
        let item1 = ClipboardItem(id: UUID(), preview: "A", representations: [:])
        let item2 = ClipboardItem(id: UUID(), preview: "A", representations: [:])

        XCTAssertNotEqual(item1, item2)
    }

    // MARK: - Total Size

    func testTotalSize() {
        let representations = [
            "type1": Data(repeating: 0, count: 100),
            "type2": Data(repeating: 0, count: 50)
        ]
        let item = ClipboardItem(preview: "Test", representations: representations)

        XCTAssertEqual(item.totalSize, 150)
    }
}
