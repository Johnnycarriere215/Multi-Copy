// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation

/// Utility for encoding and decoding clipboard items to/from JSON.
/// Used primarily for history persistence and import/export operations.
public enum ClipboardItemCoder {

    /// JSON encoder configured for clipboard items.
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// JSON decoder configured for clipboard items.
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Encodes a clipboard item to JSON data.
    public static func encode(_ item: ClipboardItem) throws -> Data {
        try encoder.encode(item)
    }

    /// Decodes a clipboard item from JSON data.
    public static func decode(from data: Data) throws -> ClipboardItem {
        try decoder.decode(ClipboardItem.self, from: data)
    }

    /// Encodes an array of clipboard items to JSON data.
    public static func encodeArray(_ items: [ClipboardItem]) throws -> Data {
        try encoder.encode(items)
    }

    /// Decodes an array of clipboard items from JSON data.
    public static func decodeArray(from data: Data) throws -> [ClipboardItem] {
        try decoder.decode([ClipboardItem].self, from: data)
    }

    /// Computes the size of encoded JSON data for a clipboard item.
    public static func encodedSize(of item: ClipboardItem) -> Int {
        (try? encode(item))?.count ?? 0
    }
}
