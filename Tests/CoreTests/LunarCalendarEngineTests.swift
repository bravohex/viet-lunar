import XCTest
@testable import VietLunarCore

final class LunarCalendarEngineTests: XCTestCase {
    private let engine = LunarCalendarEngine()

    func testCuratedSolarToLunarGoldenVectors() throws {
        let vectors: [(SolarDate, LunarDate)] = [
            try vector(1984, 2, 1, 1983, 12, 30, false),
            try vector(1984, 2, 2, 1984, 1, 1, false),
            try vector(2004, 3, 21, 2004, 2, 1, true),
            try vector(2004, 4, 18, 2004, 2, 29, true),
            try vector(2004, 4, 19, 2004, 3, 1, false),
            try vector(2020, 8, 18, 2020, 6, 29, false),
            try vector(2025, 8, 18, 2025, 6, 25, true),
            try vector(2033, 11, 22, 2033, 11, 1, false),
            try vector(2033, 12, 21, 2033, 11, 30, false),
            try vector(2033, 12, 22, 2033, 11, 1, true),
            try vector(2034, 1, 19, 2033, 11, 29, true),
            try vector(2034, 1, 20, 2033, 12, 1, false)
        ]

        for vector in vectors {
            XCTAssertEqual(try engine.lunarDate(for: vector.0), vector.1)
            XCTAssertEqual(try engine.solarDate(for: vector.1), vector.0)
        }
    }

    func testTetBoundaryChangesLunarYear() throws {
        let beforeTet = try SolarDate(validatingYear: 1984, month: 2, day: 1)
        let tet = try SolarDate(validatingYear: 1984, month: 2, day: 2)
        XCTAssertEqual(try engine.lunarDate(for: beforeTet).year, 1983)
        XCTAssertEqual(try engine.lunarDate(for: tet).year, 1984)
        XCTAssertEqual(try engine.lunarDate(for: tet).day, 1)
    }

    func testMonthLengthsAndLeapMonthMetadata() throws {
        XCTAssertEqual(try engine.leapMonth(inLunarYear: 2004), 2)
        XCTAssertEqual(try engine.monthLength(year: 2004, month: 2, isLeapMonth: true), 29)
        XCTAssertEqual(try engine.leapMonth(inLunarYear: 2025), 6)
        XCTAssertNil(try engine.leapMonth(inLunarYear: 2024))
    }

    func testDayThirtyIsRejectedInTwentyNineDayMonth() throws {
        let invalid = try LunarDate(
            validatingYear: 2004,
            month: 2,
            day: 30,
            isLeapMonth: true
        )
        XCTAssertThrowsError(try engine.solarDate(for: invalid)) { error in
            XCTAssertEqual(
                error as? LunarCalendarError,
                .dayExceedsMonthLength(day: 30, length: 29)
            )
        }
    }

    func testInvalidLeapFlagIsRejected() throws {
        let invalid = try LunarDate(
            validatingYear: 2024,
            month: 2,
            day: 1,
            isLeapMonth: true
        )
        XCTAssertThrowsError(try engine.solarDate(for: invalid)) { error in
            XCTAssertEqual(
                error as? LunarCalendarError,
                .invalidLeapMonth(requested: 2, actual: nil)
            )
        }
    }

    func testSupportedRangeEdgesRoundTrip() throws {
        for solarDate in [engine.supportedSolarRange.lowerBound, engine.supportedSolarRange.upperBound] {
            let lunarDate = try engine.lunarDate(for: solarDate)
            XCTAssertEqual(try engine.solarDate(for: lunarDate), solarDate)
        }
    }

    func testEveryGeneratedMonthBoundaryRoundTripsWhenSupported() throws {
        for record in GeneratedLunarYearTableData.records {
            for index in 0..<record.monthCount {
                let logical = try record.logicalMonth(atSequentialIndex: index)
                let monthLength = try record.monthLength(atSequentialIndex: index)

                for day in [1, monthLength] {
                    let lunarDate = try LunarDate(
                        validatingYear: record.year,
                        month: logical.month,
                        day: day,
                        isLeapMonth: logical.isLeap
                    )

                    do {
                        let solarDate = try engine.solarDate(for: lunarDate)
                        XCTAssertEqual(try engine.lunarDate(for: solarDate), lunarDate)
                    } catch LunarCalendarError.unsupportedSolarDate(let solarDate) {
                        XCTAssertFalse(engine.supportedSolarRange.contains(solarDate))
                    }
                }
            }
        }
    }

    func testDatesOutsideSupportedRangeThrowTypedErrors() throws {
        let below = try SolarDate(validatingYear: 1799, month: 12, day: 31)
        let above = try SolarDate(validatingYear: 2200, month: 1, day: 1)

        XCTAssertThrowsError(try engine.lunarDate(for: below)) { error in
            XCTAssertEqual(error as? LunarCalendarError, .unsupportedSolarDate(below))
        }
        XCTAssertThrowsError(try engine.lunarDate(for: above)) { error in
            XCTAssertEqual(error as? LunarCalendarError, .unsupportedSolarDate(above))
        }
        XCTAssertThrowsError(try engine.leapMonth(inLunarYear: 1700)) { error in
            XCTAssertEqual(error as? LunarCalendarError, .unsupportedLunarYear(1700))
        }
    }

    private func vector(
        _ solarYear: Int,
        _ solarMonth: Int,
        _ solarDay: Int,
        _ lunarYear: Int,
        _ lunarMonth: Int,
        _ lunarDay: Int,
        _ isLeapMonth: Bool
    ) throws -> (SolarDate, LunarDate) {
        (
            try SolarDate(
                validatingYear: solarYear,
                month: solarMonth,
                day: solarDay
            ),
            try LunarDate(
                validatingYear: lunarYear,
                month: lunarMonth,
                day: lunarDay,
                isLeapMonth: isLeapMonth
            )
        )
    }
}
