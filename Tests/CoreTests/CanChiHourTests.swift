import Foundation
import XCTest
@testable import VietLunarCore

final class CanChiHourTests: XCTestCase {
    private let calculator = CanChiCalculator()

    func testAllSpecifiedHourBranchBoundaries() throws {
        let solarDate = try SolarDate(validatingYear: 2004, month: 4, day: 19)
        let cases: [(Int, Int, EarthlyBranch)] = [
            (22, 59, .hoi),
            (23, 0, .ty),
            (23, 59, .ty),
            (0, 0, .ty),
            (0, 59, .ty),
            (1, 0, .suu),
            (2, 59, .suu),
            (3, 0, .dan),
            (4, 59, .dan),
            (5, 0, .mao),
            (6, 59, .mao),
            (7, 0, .thin),
            (8, 59, .thin),
            (9, 0, .tySnake),
            (10, 59, .tySnake),
            (11, 0, .ngo),
            (12, 59, .ngo),
            (13, 0, .mui),
            (14, 59, .mui),
            (15, 0, .than),
            (16, 59, .than),
            (17, 0, .dau),
            (18, 59, .dau),
            (19, 0, .tuat),
            (20, 59, .tuat),
            (21, 0, .hoi)
        ]

        for (hour, minute, expectedBranch) in cases {
            let localTime = try LocalTime(validatingHour: hour, minute: minute)
            XCTAssertEqual(
                calculator.hour(for: solarDate, at: localTime).branch,
                expectedBranch,
                "Unexpected branch at \(hour):\(minute)"
            )
        }
    }

    func testEveryMinuteFallsInItsTwoHourBranchInterval() throws {
        let solarDate = try SolarDate(validatingYear: 2004, month: 4, day: 19)

        for hour in 0..<24 {
            for minute in 0..<60 {
                let localTime = try LocalTime(validatingHour: hour, minute: minute)
                let expectedIndex = ((hour + 1) / 2) % 12
                XCTAssertEqual(
                    calculator.hour(for: solarDate, at: localTime).branch.rawValue,
                    expectedIndex
                )
            }
        }
    }

    func testCivilMidnightSplitsTyHourStemAcrossDates() throws {
        let beforeMidnightDate = try SolarDate(validatingYear: 2004, month: 4, day: 19)
        let afterMidnightDate = try SolarDate(validatingYear: 2004, month: 4, day: 20)
        let beforeMidnightTime = try LocalTime(validatingHour: 23, minute: 59)
        let afterMidnightTime = try LocalTime(validatingHour: 0, minute: 0)

        XCTAssertEqual(
            calculator.hour(for: beforeMidnightDate, at: beforeMidnightTime).description,
            "Nhâm Tý"
        )
        XCTAssertEqual(
            calculator.hour(for: afterMidnightDate, at: afterMidnightTime).description,
            "Giáp Tý"
        )
    }

    func testStartOfZiHourUsesNextCivilDaysStemAt2300() throws {
        let beforeMidnightDate = try SolarDate(validatingYear: 2004, month: 4, day: 19)
        let afterMidnightDate = try SolarDate(validatingYear: 2004, month: 4, day: 20)
        let beforeMidnightTime = try LocalTime(validatingHour: 23, minute: 0)
        let afterMidnightTime = try LocalTime(validatingHour: 0, minute: 0)

        let ziStart = calculator.hour(
            for: beforeMidnightDate,
            at: beforeMidnightTime,
            boundaryPolicy: .startOfZiHour
        )
        let afterMidnight = calculator.hour(
            for: afterMidnightDate,
            at: afterMidnightTime,
            boundaryPolicy: .startOfZiHour
        )

        XCTAssertEqual(ziStart, afterMidnight)
        XCTAssertEqual(ziStart.description, "Giáp Tý")
        XCTAssertEqual(
            calculator.day(
                for: beforeMidnightDate,
                at: beforeMidnightTime,
                boundaryPolicy: .startOfZiHour
            ),
            calculator.day(for: afterMidnightDate)
        )
    }

    func testBoundaryPolicyDefaultAndCodableValueAreStable() throws {
        XCTAssertEqual(CanChiDayBoundaryPolicy.defaultValue, .civilMidnight)

        let encoded = try JSONEncoder().encode(CanChiDayBoundaryPolicy.civilMidnight)
        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), #""civilMidnight""#)
        XCTAssertEqual(
            try JSONDecoder().decode(CanChiDayBoundaryPolicy.self, from: encoded),
            .civilMidnight
        )
    }
}
