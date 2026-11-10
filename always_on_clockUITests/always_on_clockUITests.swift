//
//  always_on_clockUITests.swift
//  always_on_clockUITests
//
//  Created by Kirill Milititskiy on 07/11/2026.
//

import XCTest
import UIKit

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
    func testAutomaticLuminanceScheduleAndManualRestoration() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-clockUsageAcknowledged", "YES"]
        app.launch()
        app.buttons["clock.settings"].tap()
        let settings = app.collectionViews.firstMatch
        let schedule = app.switches["settings.scheduleEnabled"]
        XCTAssertTrue(schedule.waitForExistence(timeout: 5))
        if schedule.value as? String == "1" {
            schedule.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        }
        let manual = app.sliders["settings.luminance"]
        XCTAssertTrue(manual.waitForExistence(timeout: 5))
        manual.adjust(toNormalizedSliderPosition: 0.5)
        let manualValue = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Clock luminance:'")).firstMatch.label
        schedule.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(schedule.value as? String, "1")
        XCTAssertTrue(app.descendants(matching: .any)["settings.nightStart"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.descendants(matching: .any)["settings.dayStart"].exists, app.debugDescription)
        let nightPicker = app.datePickers["settings.nightStart"]
        let originalTime = nightPicker.buttons.firstMatch.value as? String
        nightPicker.buttons.firstMatch.tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.firstMatch.swipeUp()
        app.buttons["PopoverDismissRegion"].tap()
        let changedTime = nightPicker.buttons.firstMatch.value as? String
        XCTAssertNotNil(changedTime)
        XCTAssertNotEqual(changedTime, originalTime)
        let day = app.sliders["settings.dayLuminance"]
        let night = app.sliders["settings.nightLuminance"]
        for _ in 0..<4 where !day.isHittable { settings.swipeUp() }
        XCTAssertTrue(day.isHittable)
        day.adjust(toNormalizedSliderPosition: 1)
        for _ in 0..<4 where !night.isHittable { settings.swipeUp() }
        XCTAssertTrue(night.isHittable)
        night.adjust(toNormalizedSliderPosition: 0)
        app.buttons["settings.done"].tap()

        let readout = app.staticTexts["clock.luminance"]
        XCTAssertTrue(readout.waitForExistence(timeout: 5))
        XCTAssertTrue(readout.label.contains("100% (DAY)") || readout.label.contains("10% (NIGHT)"), readout.label)
        app.terminate()
        app.launch()
        XCTAssertTrue(readout.waitForExistence(timeout: 5))
        XCTAssertTrue(readout.label.contains("100% (DAY)") || readout.label.contains("10% (NIGHT)"), readout.label)
        app.buttons["clock.settings"].tap()
        XCTAssertEqual(schedule.value as? String, "1")
        XCTAssertEqual(nightPicker.buttons.firstMatch.value as? String, changedTime)
        schedule.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertTrue(manual.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Clock luminance:'")).firstMatch.label, manualValue)
        app.buttons["settings.done"].tap()
        XCTAssertTrue(readout.label.contains("(MANUAL)"))
    }

    @MainActor
    func testLuminanceDimsClockControls() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-clockUsageAcknowledged", "YES"]
        app.launch()

        let buttons = ["clock.theme", "clock.crt", "clock.settings"].map { app.buttons[$0] }
        XCTAssertTrue(buttons[2].waitForExistence(timeout: 10))
        let themeName = app.staticTexts["clock.themeName"]
        for _ in 0..<4 where !themeName.label.contains("AMBER / RUST") {
            buttons[0].tap()
        }
        XCTAssertTrue(themeName.label.contains("AMBER / RUST"))
        if buttons[1].value as? String != "On" { buttons[1].tap() }
        buttons[2].tap()
        let slider = app.sliders["settings.luminance"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        slider.adjust(toNormalizedSliderPosition: 0)
        app.buttons["settings.done"].tap()
        let dimPeaks = try buttons.map { try peakColorComponent(in: $0.screenshot().image) }
        XCTAssertTrue(buttons.allSatisfy(\.isHittable))
        buttons[0].tap()
        XCTAssertTrue(themeName.label.contains("CYBERPUNK"))
        for _ in 0..<3 { buttons[0].tap() }
        XCTAssertTrue(themeName.label.contains("AMBER / RUST"))
        buttons[1].tap()
        XCTAssertEqual(buttons[1].value as? String, "Off")
        buttons[1].tap()
        XCTAssertEqual(buttons[1].value as? String, "On")

        buttons[2].tap()
        slider.adjust(toNormalizedSliderPosition: 1)
        app.buttons["settings.done"].tap()
        let brightPeaks = try buttons.map { try peakColorComponent(in: $0.screenshot().image) }
        for (dim, bright) in zip(dimPeaks, brightPeaks) {
            XCTAssertGreaterThan(bright, dim * 2, "Control should visibly dim at 10% luminance")
        }

        buttons[0].tap()
        XCTAssertTrue(app.staticTexts["clock.themeName"].label.contains("CYBERPUNK"))
        buttons[1].tap()
        XCTAssertEqual(buttons[1].value as? String, "Off")
    }

    private func peakColorComponent(in image: UIImage) throws -> Int {
        let cgImage = try XCTUnwrap(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ))
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return stride(from: 0, to: pixels.count, by: 4).reduce(0) { peak, index in
            max(peak, Int(pixels[index]), Int(pixels[index + 1]), Int(pixels[index + 2]))
        }
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
    func testBatteryPercentageOnDevice() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Battery level must be verified on a physical iPhone.")
        #else
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-clockUsageAcknowledged", "YES"]
        app.launch()

        app.buttons["clock.settings"].tap()
        let settings = app.collectionViews.firstMatch
        let toggle = app.switches["settings.showBattery"]
        for _ in 0..<4 where !toggle.isHittable { settings.swipeUp() }
        XCTAssertTrue(toggle.isHittable)
        if toggle.value as? String == "1" {
            toggle.tap()
        }
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        app.buttons["settings.done"].tap()

        let battery = app.otherElements["clock.battery"]
        XCTAssertTrue(battery.waitForExistence(timeout: 10))
        let available = NSPredicate(format: "label MATCHES %@", "Battery (100|[0-9]{1,2}) percent.*")
        expectation(for: available, evaluatedWith: battery)
        waitForExpectations(timeout: 20)

        XCUIDevice.shared.press(.home)
        app.activate()
        expectation(for: available, evaluatedWith: battery)
        waitForExpectations(timeout: 20)
        app.terminate()
        app.launch()
        XCTAssertTrue(battery.waitForExistence(timeout: 10))
        expectation(for: available, evaluatedWith: battery)
        waitForExpectations(timeout: 20)
        #endif
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

    @MainActor
    func testCRTFilterToggleAndPersistence() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-clockUsageAcknowledged", "YES"]
        app.launch()

        let crt = app.buttons["clock.crt"]
        let theme = app.buttons["clock.theme"]
        let settings = app.buttons["clock.settings"]
        XCTAssertTrue(crt.waitForExistence(timeout: 10))
        XCTAssertTrue(crt.isHittable)
        if crt.value as? String == "On" { crt.tap() }
        XCTAssertEqual(crt.value as? String, "Off")

        crt.tap()
        XCTAssertEqual(crt.value as? String, "On")
        theme.tap()
        XCTAssertTrue(app.otherElements["clock.time"].exists)
        XCTAssertTrue(settings.isHittable)
        app.terminate()
        app.launch()
        XCTAssertTrue(crt.waitForExistence(timeout: 10))
        XCTAssertEqual(crt.value as? String, "On")
        crt.tap()
        XCTAssertEqual(crt.value as? String, "Off")
        app.terminate()
        app.launch()
        XCTAssertTrue(crt.waitForExistence(timeout: 10))
        XCTAssertEqual(crt.value as? String, "Off")
    }
}
