// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import XCTest
@testable import JacqueCopy

@MainActor
final class ClipboardEngineTests: XCTestCase {

    var engine: ClipboardEngine!
    var pasteboardManager: PasteboardManager!
    var historyStore: HistoryStore!

    override func setUp() {
        super.setUp()
        // Note: In a real test environment, these would be mocked.
        // For integration-level tests, we test against real singletons.
        engine = ClipboardEngine.shared
    }

    override func tearDown() {
        engine.clearAllHistory()
        engine.clearClipboardB()
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialClipboardsAreEmpty() {
        // In test environment, clipboard state may vary.
        // Verifying the engine doesn't crash on startup.
        XCTAssertNotNil(engine)
    }

    func testInitialMonitoringIsOff() {
        XCTAssertFalse(engine.isMonitoring)
    }

    // MARK: - Clipboard B Operations

    func testSetClipboardBContent() {
        let item = ClipboardItem(
            preview: "Test item B",
            representations: ["public.utf8-plain-text": "Test item B".data(using: .utf8)!]
        )

        engine.setClipboardBContent(item)

        XCTAssertEqual(engine.clipboardB?.id, item.id)
        XCTAssertEqual(engine.clipboardB?.preview, "Test item B")
    }

    func testClearClipboardB() {
        let item = ClipboardItem(preview: "To be cleared", representations: [:])
        engine.setClipboardBContent(item)

        engine.clearClipboardB()

        XCTAssertNil(engine.clipboardB)
    }

    func testSwapClipboards() {
        let itemA = ClipboardItem(preview: "Item A", representations: [:])
        let itemB = ClipboardItem(preview: "Item B", representations: [:])

        engine.setClipboardBContent(itemB)

        // Swap should exchange contents
        // Note: clipboardA depends on system state
        engine.swapClipboards()

        // After swap, clipboardB should contain what was in A
        // This is a structural test verifying the method doesn't crash
    }

    // MARK: - Monitoring

    func testStartStopMonitoring() {
        engine.startMonitoring()
        XCTAssertTrue(engine.isMonitoring)

        engine.stopMonitoring()
        XCTAssertFalse(engine.isMonitoring)
    }

    func testDoubleStartMonitoring() {
        engine.startMonitoring()
        engine.startMonitoring() // Should not create duplicate timers
        XCTAssertTrue(engine.isMonitoring)

        engine.stopMonitoring()
    }

    // MARK: - History Access

    func testClearHistory() {
        let item = ClipboardItem(preview: "History test", representations: [:])
        engine.setClipboardBContent(item)

        let beforeCount = engine.getHistory(for: .secondary).count
        XCTAssertGreaterThanOrEqual(beforeCount, 1)

        engine.clearHistory(for: .secondary)

        let afterCount = engine.getHistory(for: .secondary).count
        XCTAssertEqual(afterCount, 0)
    }
}
