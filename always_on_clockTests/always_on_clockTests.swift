//
//  always_on_clockTests.swift
//  always_on_clockTests
//
//  Created by Kirill Milititskiy on 07/11/2026.
//

import Testing
import UIKit
import CoreText
import SwiftUI
@testable import always_on_clock

struct always_on_clockTests {
    @Test @MainActor func idleTimerTracksSceneActivity() {
        let previousValue = UIApplication.shared.isIdleTimerDisabled
        defer { UIApplication.shared.isIdleTimerDisabled = previousValue }

        setClockIdleTimer(for: .active)
        #expect(UIApplication.shared.isIdleTimerDisabled)
        setClockIdleTimer(for: .inactive)
        #expect(!UIApplication.shared.isIdleTimerDisabled)
        setClockIdleTimer(for: .background)
        #expect(!UIApplication.shared.isIdleTimerDisabled)
        setClockIdleTimer(for: .active)
        #expect(UIApplication.shared.isIdleTimerDisabled)
    }

    @Test func clockFontIsRegisteredAndContainsClockCharacters() throws {
        let uiFont = try #require(UIFont(name: "ClockDots-Regular", size: 64))
        #expect(uiFont.fontName == "ClockDots-Regular")

        let font = CTFontCreateWithName(uiFont.fontName as CFString, 64, nil)
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789:.,-/' ".utf16)
        var glyphs = Array(repeating: CGGlyph(), count: characters.count)
        #expect(CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count))
        #expect(glyphs.allSatisfy { $0 != 0 })

        var advances = Array(repeating: CGSize.zero, count: glyphs.count)
        CTFontGetAdvancesForGlyphs(font, .horizontal, glyphs, &advances, glyphs.count)
        #expect(advances.allSatisfy { $0.width == advances[0].width })
    }

    @Test func inactiveDigitGridsMatchActiveDigitGeometry() throws {
        let active = try #require(UIFont(name: "ClockDots-Regular", size: 64))
        let inactive = try #require(UIFont(name: "ClockDotsInactive-Regular", size: 64))
        let activeFont = CTFontCreateWithName(active.fontName as CFString, 64, nil)
        let inactiveFont = CTFontCreateWithName(inactive.fontName as CFString, 64, nil)

        for character in "0123456789".utf16 {
            var activeGlyph = CGGlyph()
            var inactiveGlyph = CGGlyph()
            var input = character
            #expect(CTFontGetGlyphsForCharacters(activeFont, &input, &activeGlyph, 1))
            #expect(CTFontGetGlyphsForCharacters(inactiveFont, &input, &inactiveGlyph, 1))
            let activePath = try #require(CTFontCreatePathForGlyph(activeFont, activeGlyph, nil))
            let inactivePath = try #require(CTFontCreatePathForGlyph(inactiveFont, inactiveGlyph, nil))
            let activeDots = dotOrigins(in: activePath)
            let inactiveDots = dotOrigins(in: inactivePath)
            #expect(inactiveDots.count == 35)
            #expect(activeDots.count < inactiveDots.count)
            #expect(activeDots.allSatisfy { inactiveDots.contains($0) })

            var activeAdvance = CGSize.zero
            var inactiveAdvance = CGSize.zero
            CTFontGetAdvancesForGlyphs(activeFont, .horizontal, &activeGlyph, &activeAdvance, 1)
            CTFontGetAdvancesForGlyphs(inactiveFont, .horizontal, &inactiveGlyph, &inactiveAdvance, 1)
            #expect(activeAdvance == inactiveAdvance)
        }
    }

    private func dotOrigins(in path: CGPath) -> [CGPoint] {
        var points: [CGPoint] = []
        path.applyWithBlock { element in
            if element.pointee.type == .moveToPoint {
                points.append(element.pointee.points[0])
            }
        }
        return points
    }

    @Test func clockTimeFormatsMidnightNoonAndTimeZones() throws {
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        let offset = try #require(TimeZone(secondsFromGMT: 3_600))
        let locale = Locale(identifier: "en_US")
        let calendar = Calendar(identifier: .gregorian)
        let midnight = Date(timeIntervalSince1970: 0)
        let twelve = ClockTime(date: midnight, format: .twelveHour, locale: locale, timeZone: utc, calendar: calendar)
        #expect(twelve.hour == "12")
        #expect(twelve.minute == "00")
        #expect(twelve.period == "AM")

        let noon = ClockTime(date: midnight.addingTimeInterval(12 * 3_600 + 61),
                             format: .twelveHour, locale: locale, timeZone: utc, calendar: calendar)
        #expect(noon.hour == "12")
        #expect(noon.minute == "01")
        #expect(noon.second == "01")
        #expect(noon.period == "PM")

        let twentyFour = ClockTime(date: midnight, format: .twentyFourHour,
                                   locale: locale, timeZone: offset, calendar: calendar)
        #expect(twentyFour.hour == "01")
        #expect(twentyFour.period == nil)
    }

    @Test func systemTimeFormatFollowsLocale() throws {
        let timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let date = Date(timeIntervalSince1970: 0)
        let calendar = Calendar(identifier: .gregorian)
        let us = ClockTime(date: date, format: .system, locale: Locale(identifier: "en_US"),
                           timeZone: timeZone, calendar: calendar)
        let uk = ClockTime(date: date, format: .system, locale: Locale(identifier: "en_GB"),
                           timeZone: timeZone, calendar: calendar)
        #expect(us.period == "AM")
        #expect(uk.period == nil)
        #expect(uk.hour == "00")
    }

    @Test func movementChangesEveryFiveMinutesAndStaysBounded() {
        let start = Date(timeIntervalSince1970: 0)
        #expect(clockMovement(for: start, enabled: false) == .zero)
        #expect(clockMovement(for: start.addingTimeInterval(299), enabled: true) == .zero)
        #expect(clockMovement(for: start.addingTimeInterval(300), enabled: true) == CGSize(width: 4, height: 0))
        #expect(clockMovement(for: start.addingTimeInterval(2_700), enabled: true) == .zero)
        for interval in -9...9 {
            let position = clockMovement(for: start.addingTimeInterval(Double(interval * 300)), enabled: true)
            #expect(abs(position.width) <= 4 && abs(position.height) <= 4)
        }
    }

    @Test func themesUseRequestedColorsAndCycleInOrder() {
        let themes = ThemeMode.allCases
        #expect(themes == [.amber, .cyberpunk, .bladeRunner1982, .bladeRunner2049])
        #expect(themes.map(\.backgroundHex) == [0x08080A, 0x05050A, 0x0A0908, 0x0D0B0A])
        #expect(themes.map(\.activeHex) == [0xC84B31, 0x00F0FF, 0xE2A03F, 0xFF5722])
        #expect(themes.map(\.secondaryHex) == [0x4A3B32, 0x4A2E4B, 0x3D332A, 0x4D322A])
        #expect(themes.map(\.next) == [.cyberpunk, .bladeRunner1982, .bladeRunner2049, .amber])
    }
}
