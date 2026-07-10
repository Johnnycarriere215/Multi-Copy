// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

#if os(Windows)

import Foundation
import Win32Bridge

/// Windows-specific clipboard provider using the Win32 clipboard API.
final class WindowsClipboardProvider: ClipboardProvider {
    private var lastChangeCount: UInt32 = 0
    private let operationLock = NSLock()

    // Sensitive/excluded clipboard format names to skip
    private static let excludedFormats: Set<String> = [
        "CF_LOCALE",
        "CF_OWNERDISPLAY",
        "CF_DSPTEXT",
        "CF_DSPBITMAP",
        "CF_DSPMETAFILEPICT",
        "CF_DSPENHMETAFILE"
    ]

    init() {
        lastChangeCount = win32_clipboard_get_sequence()
    }

    func captureCurrent() -> [String: Data] {
        operationLock.lock()
        defer { operationLock.unlock() }

        let formatCount = win32_clipboard_format_count()
        guard formatCount > 0 else { return [:] }

        var representations: [String: Data] = [:]

        for i in 0..<formatCount {
            guard let formatNamePtr = win32_clipboard_format_at(i) else { continue }
            let formatName = String(cString: formatNamePtr)
            win32_free(formatNamePtr)

            guard !Self.excludedFormats.contains(formatName) else { continue }

            var dataSize: Int32 = 0
            guard let dataPtr = win32_clipboard_get_data(formatName, &dataSize),
                  dataSize > 0 else { continue }

            let data = Data(bytes: dataPtr, count: Int(dataSize))
            win32_free(dataPtr)
            representations[formatName] = data
        }

        return representations
    }

    func writeRepresentations(_ representations: [String: Data]) {
        operationLock.lock()
        defer { operationLock.unlock() }

        let formatNames = representations.map { $0.key }
        let dataBuffers = representations.map { $0.value }

        // Build C-compatible arrays
        var cFormatNames: [UnsafePointer<CChar>?] = formatNames.map { ($0 as NSString).utf8String }
        var cDataBuffers: [UnsafePointer<UInt8>?] = dataBuffers.map { $0.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: UInt8.self) } }
        var cDataSizes: [Int32] = dataBuffers.map { Int32($0.count) }

        let success = cFormatNames.withUnsafeMutableBufferPointer { formatsPtr in
            cDataBuffers.withUnsafeMutableBufferPointer { dataPtr in
                cDataSizes.withUnsafeMutableBufferPointer { sizesPtr in
                    win32_clipboard_set_data(
                        UnsafePointer(formatsPtr.baseAddress),
                        UnsafePointer(dataPtr.baseAddress),
                        sizesPtr.baseAddress,
                        Int32(representations.count)
                    )
                }
            }
        }
        if !success {
            DiagnosticsService.shared.warning("Failed to write to Windows clipboard", category: "Clipboard")
        }
    }

    func hasChanged() -> Bool {
        return win32_clipboard_has_changed(&lastChangeCount)
    }

    func availableTypes() -> [String] {
        let formatCount = win32_clipboard_format_count()
        var types: [String] = []
        for i in 0..<formatCount {
            if let namePtr = win32_clipboard_format_at(i) {
                types.append(String(cString: namePtr))
                win32_free(namePtr)
            }
        }
        return types
    }

    func frontmostApplicationBundleID() -> String? {
        guard let ptr = win32_get_foreground_process() else { return nil }
        let name = String(cString: ptr)
        win32_free(ptr)
        return name
    }
}

#endif
