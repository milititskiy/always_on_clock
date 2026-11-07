//
//  always_on_clockUITests.swift
//  always_on_clockUITests
//
//  Created by Kirill Milititskiy on 07/11/2026.
//

import XCTest

final class always_on_clockUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testClockInBothLandscapeOrientations() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-clockUsageAcknowledged", "YES"]
        app.launch()

        let time = app.otherElements["clock.time"]
        let seconds = app.descendants(matching: .any)["clock.seconds"]
        XCTAssertTrue(time.waitForExistence(timeout: 10))
        XCTAssertTrue(seconds.exists)
        let initialSeconds = seconds.label
        let secondsChanged = expectation(for: NSPredicate(format: "label != %@", initialSeconds),
                                         evaluatedWith: seconds)
        wait(for: [secondsChanged], timeout: 5)
        XCTAssertGreaterThan(app.windows.firstMatch.frame.width, app.windows.firstMatch.frame.height)

        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertTrue(time.exists)
        XCTAssertTrue(seconds.exists)
        XCTAssertGreaterThan(app.windows.firstMatch.frame.width, app.windows.firstMatch.frame.height)
    }

    @MainActor
    func testSettingsPersist() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-clockUsageAcknowledged", "YES"]
        app.launch()
        app.buttons["clock.settings"].tap()
        let slider = app.sliders["settings.luminance"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        slider.adjust(toNormalizedSliderPosition: 0)
        app.buttons["12-hour"].tap()
        app.buttons["settings.done"].tap()
        XCTAssertTrue(app.staticTexts["clock.period"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["clock.luminance"].label.contains("10%"))

        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["clock.period"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["clock.luminance"].label.contains("10%"))
        app.buttons["clock.settings"].tap()
        app.buttons["24-hour"].tap()
        app.buttons["settings.done"].tap()
        XCTAssertFalse(app.staticTexts["clock.period"].exists)
    }

    @MainActor
    func testUsageGuideAndSettingsAccess() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-clockUsageAcknowledged", "NO"]
        app.launch()
        XCTAssertTrue(app.staticTexts["A bedside clock"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["POWER & BATTERY"].exists)
        XCTAssertTrue(app.staticTexts["SAFE CHARGING"].exists)
        XCTAssertTrue(app.staticTexts["DISPLAY CARE"].exists)
        let guide = app.scrollViews["usage.guide"]
        let batteryLink = app.buttons["Battery charging and lifespan"]
        let safetyLink = app.buttons["iPhone charging safety"]
        let displayLink = app.buttons["OLED display care"]
        for _ in 0..<8 where !displayLink.isHittable {
            guide.swipeUp()
        }
        XCTAssertTrue(batteryLink.isHittable)
        XCTAssertTrue(safetyLink.isHittable)
        XCTAssertTrue(displayLink.isHittable)
        app.buttons["usage.continue"].tap()
        XCTAssertTrue(app.otherElements["clock.time"].waitForExistence(timeout: 10))

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.otherElements["clock.time"].waitForExistence(timeout: 10))
        app.buttons["clock.settings"].tap()
        let settings = app.collectionViews.firstMatch
        for _ in 0..<4 where !app.buttons["settings.about"].isHittable { settings.swipeUp() }
        app.buttons["settings.about"].tap()
        XCTAssertTrue(app.staticTexts["A bedside clock"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["POWER & BATTERY"].exists)
    }

    @MainActor
    func testOptionalClockFeaturesPersist() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-clockUsageAcknowledged", "YES"]
        app.launch()
        app.buttons["clock.settings"].tap()
        let settings = app.collectionViews.firstMatch
        let date = app.switches["settings.showDate"]
        settings.swipeUp()
        settings.swipeUp()
        for _ in 0..<4 where !date.isHittable { settings.swipeUp() }
        XCTAssertTrue(date.isHittable)
        let battery = app.switches["settings.showBattery"]
        let movement = app.switches["settings.displayMovement"]
        for toggle in [date, battery, movement] {
            if !toggle.isHittable { settings.swipeUp() }
            if (toggle.value as? String) != "1" {
                toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
            }
            let enabled = expectation(for: NSPredicate(format: "value == %@", "1"), evaluatedWith: toggle)
            wait(for: [enabled], timeout: 5)
        }
        app.buttons["settings.done"].tap()
        XCTAssertTrue(app.staticTexts["clock.date"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.otherElements["clock.battery"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["clock.date"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["clock.battery"].exists)
        app.buttons["clock.settings"].tap()
        for _ in 0..<4 where !movement.isHittable { settings.swipeUp() }
        XCTAssertEqual(movement.value as? String, "1")
    }

    @MainActor
    func testThemeCyclingAndPersistence() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-clockUsageAcknowledged", "YES"]
        app.launch()
        let themeButton = app.buttons["clock.theme"]
        let themeName = app.staticTexts["clock.themeName"]
        XCTAssertTrue(themeButton.waitForExistence(timeout: 10))
        for _ in 0..<4 where !themeName.label.contains("AMBER / RUST") {
            themeButton.tap()
        }
        XCTAssertTrue(themeName.label.contains("AMBER / RUST"))
        for expected in ["CYBERPUNK 2077", "BLADE RUNNER 1982", "BLADE RUNNER 2049"] {
            themeButton.tap()
            XCTAssertTrue(themeName.label.contains(expected))
        }
        app.terminate()
        app.launch()
        XCTAssertTrue(themeButton.waitForExistence(timeout: 10))
        XCTAssertTrue(themeName.label.contains("BLADE RUNNER 2049"))
        themeButton.tap()
        XCTAssertTrue(themeName.label.contains("AMBER / RUST"))
    }
}
