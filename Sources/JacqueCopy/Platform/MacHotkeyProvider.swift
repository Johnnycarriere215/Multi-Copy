// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

#if os(macOS)

import Foundation
import CoreGraphics
import AppKit
import KeyboardShortcuts

/// macOS-specific hotkey provider using CGEventTap for global keyboard interception.
final class MacHotkeyProvider: HotkeyProvider {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isActive: Bool = false
    private var copyHandler: (() -> Void)?
    private var pasteHandler: (() -> Void)?
    private weak var shortcutManager: ShortcutManager?
    private weak var clipboardEngine: ClipboardEngine?

    private var isPerformingPaste = false
    private var isPerformingCopy = false

    init(shortcutManager: ShortcutManager, clipboardEngine: ClipboardEngine) {
        self.shortcutManager = shortcutManager
        self.clipboardEngine = clipboardEngine
    }

    func startListening(copyHandler: @escaping () -> Void, pasteHandler: @escaping () -> Void) -> Bool {
        guard !isActive else { return true }
        self.copyHandler = copyHandler
        self.pasteHandler = pasteHandler

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let provider = Unmanaged<MacHotkeyProvider>.fromOpaque(refcon).takeUnretainedValue()
                return provider.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        self.eventTap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        isActive = true
        return true
    }

    func stopListening() {
        guard isActive else { return }
        isActive = false
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
    }

    func simulateCopy() {
        postSyntheticKeyPress(key: 0x08, mask: .maskCommand)
    }

    func simulatePaste() {
        postSyntheticKeyPress(key: 0x09, mask: .maskCommand)
    }

    // MARK: - Private Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let cgFlags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        var nsModifiers = NSEvent.ModifierFlags()
        if cgFlags.contains(.maskCommand) { nsModifiers.insert(.command) }
        if cgFlags.contains(.maskControl)  { nsModifiers.insert(.control) }
        if cgFlags.contains(.maskAlternate) { nsModifiers.insert(.option) }
        if cgFlags.contains(.maskShift)    { nsModifiers.insert(.shift) }

        let copyShortcut = KeyboardShortcuts.getShortcut(for: .copyToClipboardB)
        let pasteShortcut = KeyboardShortcuts.getShortcut(for: .pasteFromClipboardB)

        if let shortcut = copyShortcut,
           shortcut.carbonKeyCode == UInt32(keyCode),
           shortcut.modifiers == nsModifiers {
            guard !isPerformingCopy else { return nil }
            isPerformingCopy = true
            copyHandler?()
            DispatchQueue.main.async { [weak self] in self?.isPerformingCopy = false }
            return nil
        }

        if let shortcut = pasteShortcut,
           shortcut.carbonKeyCode == UInt32(keyCode),
           shortcut.modifiers == nsModifiers {
            guard !isPerformingPaste else { return nil }
            isPerformingPaste = true
            pasteHandler?()
            DispatchQueue.main.async { [weak self] in self?.isPerformingPaste = false }
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func postSyntheticKeyPress(key: Int64, mask: CGEventFlags) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyCode = CGKeyCode(key)

        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = []
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = mask
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = mask
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        cmdUp?.flags = []

        cmdDown?.post(tap: .cghidEventTap)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
}

#endif
