// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import Foundation
import CoreGraphics
import AppKit
import KeyboardShortcuts

/// Manages global keyboard event interception using CGEventTap.
///
/// HotkeyManager intercepts the secondary clipboard shortcut keys globally
/// to power Clipboard B operations. It translates intercepted events into
/// the appropriate clipboard operations: simulate Cmd+C for secondary copy
/// and Cmd+V for secondary paste after swapping clipboard contents.
///
/// IMPORTANT: All pasteboard I/O is dispatched off the event tap thread via
/// async dispatch to main. The CGEventTap callback MUST return as fast as possible.
///
/// This implementation reads user-configured shortcuts from KeyboardShortcuts
/// so the CGEventTap respects user settings dynamically.
public final class HotkeyManager {

    // MARK: - Singleton

    public static let shared = HotkeyManager()

    // MARK: - Properties

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isActive: Bool = false
    private weak var clipboardEngine: ClipboardEngine?

    private var isPerformingPaste = false
    private var isPerformingCopy = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    @discardableResult
    public func start(engine: ClipboardEngine) -> Bool {
        guard !isActive else { return true }
        self.clipboardEngine = engine

        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                HotkeyManager.eventTapCallback(proxy: proxy, type: type, event: event, refcon: refcon)
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

    public func stop() {
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

    // MARK: - Event Tap Callback

    private static let eventTapCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
        guard let refcon = refcon else {
            return Unmanaged.passUnretained(event)
        }
        let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
        return manager.handleEvent(proxy: proxy, type: type, event: event)
    }

    /// Processes a keyboard event from the event tap.
    /// MUST return as quickly as possible — no blocking I/O.
    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let cgFlags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Build NSEvent.ModifierFlags from CGEvent flags with proper Carbon-to-Cocoa mapping.
        // CGEventFlags uses Carbon values (e.g., Control = 0x4000) while
        // NSEvent.ModifierFlags uses Cocoa values (e.g., Control = 0x40000).
        // KeyboardShortcuts stores Cocoa values, so we must convert.
        var nsModifiers = NSEvent.ModifierFlags()
        if cgFlags.contains(.maskCommand) { nsModifiers.insert(.command) }
        if cgFlags.contains(.maskControl)  { nsModifiers.insert(.control) }
        if cgFlags.contains(.maskAlternate) { nsModifiers.insert(.option) }
        if cgFlags.contains(.maskShift)    { nsModifiers.insert(.shift) }

        // Get the user-configured shortcuts
        let copyShortcut = KeyboardShortcuts.getShortcut(for: .copyToClipboardB)
        let pasteShortcut = KeyboardShortcuts.getShortcut(for: .pasteFromClipboardB)

        // Check if the pressed key combination matches the secondary COPY shortcut
        if let shortcut = copyShortcut,
           shortcut.carbonKeyCode == UInt32(keyCode),
           shortcut.modifiers == nsModifiers {
            guard !isPerformingCopy else { return nil }
            isPerformingCopy = true

            // Dispatch ALL pasteboard I/O to main thread
            performSecondaryCopy()

            return nil // Consume the event
        }

        // Check if the pressed key combination matches the secondary PASTE shortcut
        if let shortcut = pasteShortcut,
           shortcut.carbonKeyCode == UInt32(keyCode),
           shortcut.modifiers == nsModifiers {
            guard !isPerformingPaste else { return nil }
            isPerformingPaste = true

            performSecondaryPaste()

            return nil // Consume the event
        }

        // Track Cmd+C for Clipboard A history (let event pass through)
        if cgFlags.contains(.maskCommand) && !cgFlags.contains(.maskControl) && keyCode == 0x08 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.clipboardEngine?.updateClipboardAFromSystem()
            }
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - Secondary Copy

    /// Handles the secondary copy operation entirely on the main thread.
    private func performSecondaryCopy() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            defer { self.isPerformingCopy = false }

            let savedClipboardA = PasteboardManager.shared.captureCurrentPasteboard()

            // Post synthetic Cmd+C via the HID event tap
            self.postSyntheticKeyPress(key: 0x08, mask: .maskCommand)

            // After a short delay, capture the result for Clipboard B
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let newItem = PasteboardManager.shared.captureCurrentPasteboard() else {
                    if let saved = savedClipboardA {
                        PasteboardManager.shared.restorePasteboard(saved)
                    }
                    return
                }

                self?.clipboardEngine?.setClipboardBContent(newItem)

                if let saved = savedClipboardA {
                    PasteboardManager.shared.restorePasteboard(saved)
                }
            }
        }
    }

    /// Handles the secondary paste operation entirely on the main thread.
    private func performSecondaryPaste() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            defer { self.isPerformingPaste = false }

            guard let itemB = self.clipboardEngine?.clipboardB else { return }

            let savedClipboardA = PasteboardManager.shared.captureCurrentPasteboard()
            PasteboardManager.shared.writeToPasteboard(itemB)

            // Post synthetic Cmd+V
            self.postSyntheticKeyPress(key: 0x09, mask: .maskCommand)

            // Restore Clipboard A after paste processes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                PasteboardManager.shared.restorePasteboard(savedClipboardA)
            }
        }
    }

    // MARK: - Synthetic Key Press Helper

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
