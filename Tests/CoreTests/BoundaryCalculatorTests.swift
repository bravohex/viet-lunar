import Foundation
import XCTest
@testable import VietLunarCore

final class BoundaryCalculatorTests: XCTestCase {
    private let calculator = BoundaryCalculator()

    func testVietnamMidnightUsesCanonicalUTCPlusSeven() throws {
        let beforeMidnight = try instant("2026-07-19T16:59:59Z")
        XCTAssertEqual(
            try calculator.nextBoundary(
                after: beforeMidnight,
                requirements: .lunarDateOnly
            ),
            try instant("2026-07-19T17:00:00Z")
        )
    }

    func testExactVietnamMidnightAdvancesToFollowingDay() throws {
        let exactMidnight = try instant("2026-07-19T17:00:00Z")
        XCTAssertEqual(
            try calculator.nextBoundary(
                after: exactMidnight,
                requirements: .lunarDateOnly
            ),
            try instant("2026-07-20T17:00:00Z")
        )
    }

    func testCanChiHourIncludesOddHoursAndCivilMidnight() throws {
        let cases: [(String, String)] = [
            ("2026-07-19T17:00:00Z", "2026-07-19T18:00:00Z"), // 00:00 → 01:00
            ("2026-07-19T17:59:59Z", "2026-07-19T18:00:00Z"), // 00:59 → 01:00
            ("2026-07-19T18:00:00Z", "2026-07-19T20:00:00Z"), // 01:00 → 03:00
            ("2026-07-20T15:59:59Z", "2026-07-20T16:00:00Z"), // 22:59 → 23:00
            ("2026-07-20T16:00:00Z", "2026-07-20T17:00:00Z") // 23:00 → 00:00
        ]

        for (input, expected) in cases {
            XCTAssertEqual(
                try calculator.nextBoundary(
                    after: instant(input),
                    requirements: .canChiHour
                ),
                try instant(expected)
            )
        }
    }

    func testMinuteBoundaryIsStrictlyAfterInput() throws {
        let utc = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let requirements = RefreshRequirements.minute(in: utc)

        XCTAssertEqual(
            try calculator.nextBoundary(
                after: instant("2026-07-20T12:34:00Z"),
                requirements: requirements
            ),
            try instant("2026-07-20T12:35:00Z")
        )
        XCTAssertEqual(
            try calculator.nextBoundary(
                after: instant("2026-07-20T12:34:30Z"),
                requirements: requirements
            ),
            try instant("2026-07-20T12:35:00Z")
        )
    }

    func testMinuteBoundaryHandlesDaylightSavingJump() throws {
        let losAngeles = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        XCTAssertEqual(
            try calculator.nextBoundary(
                after: instant("2026-03-08T09:59:30Z"), // 01:59:30 PST
                requirements: .minute(in: losAngeles)
            ),
            try instant("2026-03-08T10:00:00Z") // 03:00:00 PDT
        )
    }

    func testCombinedRequirementsChooseEarliestBoundary() throws {
        let requirements = RefreshRequirements(
            granularities: [.vietnamMidnight, .canChiHour, .minute],
            displayedClockTimeZone: VietnamCalendarTime.timeZone
        )
        XCTAssertEqual(
            try calculator.nextBoundary(
                after: instant("2026-07-20T15:59:30Z"),
                requirements: requirements
            ),
            try instant("2026-07-20T16:00:00Z")
        )
    }

    func testEmptyRequirementsThrowTypedError() throws {
        let requirements = RefreshRequirements(
            granularities: [],
            displayedClockTimeZone: VietnamCalendarTime.timeZone
        )
        XCTAssertThrowsError(
            try calculator.nextBoundary(
                after: instant("2026-07-20T12:00:00Z"),
                requirements: requirements
            )
        ) { error in
            XCTAssertEqual(error as? BoundaryCalculationError, .noRequirements)
        }
    }

    private func instant(_ value: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: value))
    }
}
