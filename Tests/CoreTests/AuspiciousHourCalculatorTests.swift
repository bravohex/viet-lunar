import XCTest
@testable import VietLunarCore

final class AuspiciousHourCalculatorTests: XCTestCase {
    func testTraditionalMappingForEveryDayBranch() {
        let expectations: [(EarthlyBranch, [EarthlyBranch])] = [
            (.ty, [.ty, .suu, .mao, .ngo, .than, .dau]),
            (.suu, [.dan, .mao, .tySnake, .than, .tuat, .hoi]),
            (.dan, [.ty, .suu, .thin, .tySnake, .mui, .tuat]),
            (.mao, [.ty, .dan, .mao, .ngo, .mui, .dau]),
            (.thin, [.dan, .thin, .tySnake, .than, .dau, .hoi]),
            (.tySnake, [.suu, .thin, .ngo, .mui, .tuat, .hoi]),
            (.ngo, [.ty, .suu, .mao, .ngo, .than, .dau]),
            (.mui, [.dan, .mao, .tySnake, .than, .tuat, .hoi]),
            (.than, [.ty, .suu, .thin, .tySnake, .mui, .tuat]),
            (.dau, [.ty, .dan, .mao, .ngo, .mui, .dau]),
            (.tuat, [.dan, .thin, .tySnake, .than, .dau, .hoi]),
            (.hoi, [.suu, .thin, .ngo, .mui, .tuat, .hoi])
        ]

        XCTAssertEqual(expectations.map(\.0), EarthlyBranch.allCases)

        for (dayBranch, expectedBranches) in expectations {
            let hours = AuspiciousHourCalculator.hours(for: dayBranch)
            XCTAssertEqual(hours.map(\.branch), expectedBranches)
            XCTAssertEqual(hours.count, 6)
            XCTAssertEqual(Set(hours.map(\.branch)).count, 6)
        }
    }

    func testCivilIntervalsCoverTheCanonicalTwelveBranches() {
        let expected: [(EarthlyBranch, Int, Int, String)] = [
            (.ty, 23, 0, "23:00–00:59"),
            (.suu, 1, 2, "01:00–02:59"),
            (.dan, 3, 4, "03:00–04:59"),
            (.mao, 5, 6, "05:00–06:59"),
            (.thin, 7, 8, "07:00–08:59"),
            (.tySnake, 9, 10, "09:00–10:59"),
            (.ngo, 11, 12, "11:00–12:59"),
            (.mui, 13, 14, "13:00–14:59"),
            (.than, 15, 16, "15:00–16:59"),
            (.dau, 17, 18, "17:00–18:59"),
            (.tuat, 19, 20, "19:00–20:59"),
            (.hoi, 21, 22, "21:00–22:59")
        ]

        for (branch, start, end, range) in expected {
            let hour = AuspiciousHour(branch: branch)
            XCTAssertEqual(hour.civilStartHour, start)
            XCTAssertEqual(hour.civilEndHour, end)
            XCTAssertEqual(hour.civilTimeRange, range)
        }
    }

    func testDayCanChiBranchDrivesTheLookup() throws {
        let solarDate = try SolarDate(validatingYear: 2004, month: 4, day: 19)
        let dayBranch = CanChiCalculator().day(for: solarDate).branch

        XCTAssertEqual(dayBranch, .thin)
        XCTAssertEqual(
            AuspiciousHourCalculator.hours(for: dayBranch).map(\.description),
            [
                "Dần (03:00–04:59)",
                "Thìn (07:00–08:59)",
                "Tỵ (09:00–10:59)",
                "Thân (15:00–16:59)",
                "Dậu (17:00–18:59)",
                "Hợi (21:00–22:59)"
            ]
        )
    }
}
