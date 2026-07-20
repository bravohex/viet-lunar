import Foundation
import XCTest
@testable import VietLunarCore

final class VietnamCalendarTimeTests: XCTestCase {
    func testCanonicalTimeZoneIsFixedUTCPlusSeven() {
        XCTAssertEqual(
            VietnamCalendarTime.timeZone.secondsFromGMT(),
            VietnamCalendarConvention.timeZoneOffsetSeconds
        )
    }

    func testInstantImmediatelyBeforeVietnamMidnightBelongsToPreviousDay() throws {
        let instant = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-07-19T16:59:59Z")
        )
        XCTAssertEqual(
            VietnamCalendarTime.solarDate(containing: instant),
            try SolarDate(validatingYear: 2026, month: 7, day: 19)
        )
    }

    func testInstantAtVietnamMidnightBelongsToNextDay() throws {
        let instant = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-07-19T17:00:00Z")
        )
        XCTAssertEqual(
            VietnamCalendarTime.solarDate(containing: instant),
            try SolarDate(validatingYear: 2026, month: 7, day: 20)
        )
    }

    func testExtractionRemainsGregorianAtYearBoundary() throws {
        let instant = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2025-12-31T17:00:00Z")
        )
        XCTAssertEqual(
            VietnamCalendarTime.solarDate(containing: instant),
            try SolarDate(validatingYear: 2026, month: 1, day: 1)
        )
    }

    func testLocalDateTimeExtractionUsesCanonicalCivilComponents() throws {
        let instant = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-07-19T16:59:00Z")
        )
        let localDateTime = VietnamCalendarTime.localDateTime(containing: instant)

        XCTAssertEqual(
            localDateTime.solarDate,
            try SolarDate(validatingYear: 2026, month: 7, day: 19)
        )
        XCTAssertEqual(
            localDateTime.localTime,
            try LocalTime(validatingHour: 23, minute: 59)
        )
    }
}
