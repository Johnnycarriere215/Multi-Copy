// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import XCTest
@testable import JacqueCopy

final class AppSettingsTests: XCTestCase {

    var settings: AppSettings!

    override func setUp() {
        super.setUp()
        settings = AppSettings.shared
    }

    override func tearDown() {
        settings.resetAllSettings()
        super.tearDown()
    }

    // MARK: - Default Values

    func testDefaultLaunchAtLogin() {
        XCTAssertTrue(settings.launchAtLogin)
    }

    func testDefaultShowDockIcon() {
        XCTAssertFalse(settings.showDockIcon)
    }

    func testDefaultMaxHistorySize() {
        XCTAssertEqual(settings.maxHistorySize, 100)
    }

    func testDefaultTheme() {
        XCTAssertEqual(settings.theme, .blackGold)
    }

    func testDefaultAnimationSpeed() {
        XCTAssertEqual(settings.animationSpeed, .normal)
    }

    // MARK: - Setting Changes

    func testChangeMaxHistorySize() {
        settings.maxHistorySize = 50
        XCTAssertEqual(settings.maxHistorySize, 50)
    }

    func testChangeTheme() {
        settings.theme = .dark
        XCTAssertEqual(settings.theme, .dark)
    }

    // MARK: - Reset

    func testResetAllSettings() {
        // Change everything
        settings.maxHistorySize = 10
        settings.theme = .light
        settings.animationSpeed = .fast
        settings.developerMode = true

        // Reset
        settings.resetAllSettings()

        // Verify defaults
        XCTAssertEqual(settings.maxHistorySize, 100)
        XCTAssertEqual(settings.theme, .blackGold)
        XCTAssertEqual(settings.animationSpeed, .normal)
        XCTAssertFalse(settings.developerMode)
    }

    // MARK: - Theme Enum

    func testThemeAllCases() {
        let cases = AppSettings.Theme.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertTrue(cases.contains(.system))
        XCTAssertTrue(cases.contains(.light))
        XCTAssertTrue(cases.contains(.dark))
        XCTAssertTrue(cases.contains(.blackGold))
    }

    func testThemeDisplayNames() {
        XCTAssertEqual(AppSettings.Theme.system.displayName, "System")
        XCTAssertEqual(AppSettings.Theme.light.displayName, "Light")
        XCTAssertEqual(AppSettings.Theme.dark.displayName, "Dark")
        XCTAssertEqual(AppSettings.Theme.blackGold.displayName, "Black & Gold")
    }

    // MARK: - Animation Speed

    func testAnimationDuration() {
        XCTAssertEqual(AppSettings.AnimationSpeed.fast.duration, 0.15, accuracy: 0.01)
        XCTAssertEqual(AppSettings.AnimationSpeed.normal.duration, 0.25, accuracy: 0.01)
        XCTAssertEqual(AppSettings.AnimationSpeed.slow.duration, 0.40, accuracy: 0.01)
    }
}
