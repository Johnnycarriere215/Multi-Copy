// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

#if os(Windows)

import Foundation
import Win32Bridge

/// Windows-specific hotkey provider using low-level keyboard hook (SetWindowsHookEx).
/// Default secondary clipboard shortcuts: Alt+C (copy) and Alt+V (paste).
final class WindowsHotkeyProvider: HotkeyProvider {
    private var copyHandler: (() -> Void)?
    private var pasteHandler: (() -> Void)?
    private var isPerformingCopy: Bool = false
    private var isPerformingPaste: Bool = false
    private var hookHandle: UnsafeMutableRawPointer?
    private var selfRetainer: Unmanaged<WindowsHotkeyProvider>?
    private let operationLock = NSLock()

    private(set) var isActive: Bool = false

    private weak var shortcutManager: ShortcutManager?
    private weak var clipboardEngine: ClipboardEngine?

    /// Virtual key codes
    private let vkC: UInt32 = 0x43
    private let vkV: UInt32 = 0x56

    init(shortcutManager: ShortcutManager, clipboardEngine: ClipboardEngine) {
        self.shortcutManager = shortcutManager
        self.clipboardEngine = clipboardEngine
    }

    func startListening(copyHandler: @escaping () -> Void, pasteHandler: @escaping () -> Void) -> Bool {
        guard !isActive else { return true }
        self.copyHandler = copyHandler
        self.pasteHandler = pasteHandler

        // Capture self for C callback (use passRetained to prevent deallocation)
        let retained = Unmanaged.passRetained(self)
        self.selfRetainer = retained
        let selfPtr = retained.toOpaque()

        let handle = win32_hotkey_start { keyCode, modifiers, isKeyDown in
            guard isKeyDown else { return false }

            let provider = Unmanaged<WindowsHotkeyProvider>.fromOpaque(selfPtr).takeUnretainedValue()
            return provider.handleKeyEvent(keyCode: keyCode, modifiers: modifiers)
        }

        guard let handle = handle else { return false }
        self.hookHandle = handle
        isActive = true
        return true
    }

    func stopListening() {
        guard isActive, let handle = hookHandle else { return }
        isActive = false
        win32_hotkey_stop(handle)
        hookHandle = nil
        // Release the retained self reference
        selfRetainer?.release()
        selfRetainer = nil
    }

    func simulateCopy() {
        win32_simulate_copy()
    }

    func simulatePaste() {
        win32_simulate_paste()
    }

    // MARK: - Private Event Handling

    /// Handles a keyboard event from the low-level hook.
    /// On Windows, defaults are Alt+C (copy to B) and Alt+V (paste from B).
    /// - Returns: true if the event was consumed, false to let it pass through.
    private func handleKeyEvent(keyCode: UInt32, modifiers: UInt32) -> Bool {
        // Alt modifier = bit 1
        let hasAlt = (modifiers & 1) != 0
        let hasCtrl = (modifiers & 2) != 0
        let hasShift = (modifiers & 4) != 0

        // Check for secondary copy: Alt+C (no Ctrl, no Shift)
        if keyCode == vkC && hasAlt && !hasCtrl && !hasShift {
            guard !isPerformingCopy else { return false }
            isPerformingCopy = true
            copyHandler?()
            DispatchQueue.main.async { [weak self] in self?.isPerformingCopy = false }
            return true // Consume event
        }

        // Check for secondary paste: Alt+V (no Ctrl, no Shift)
        if keyCode == vkV && hasAlt && !hasCtrl && !hasShift {
            guard !isPerformingPaste else { return false }
            isPerformingPaste = true
            pasteHandler?()
            DispatchQueue.main.async { [weak self] in self?.isPerformingPaste = false }
            return true // Consume event
        }

        return false // Let event pass through
    }
}

#endif
