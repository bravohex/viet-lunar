import XCTest
@testable import VietLunarCore

final class TraditionalDayClassificationTests: XCTestCase {
    func testEveryLunarMonthGroupPartitionsAllDayBranches() {
        let expectations: [(Int, [EarthlyBranch], [EarthlyBranch], [EarthlyBranch])] = [
            (1, [.ty, .suu, .tySnake, .mui], [.ngo, .mao, .hoi, .dau], [.dan, .thin, .than, .tuat]),
            (2, [.dan, .mao, .mui, .dau], [.than, .tySnake, .suu, .hoi], [.ty, .thin, .ngo, .tuat]),
            (3, [.thin, .tySnake, .dau, .hoi], [.tuat, .mui, .suu, .mao], [.ty, .dan, .ngo, .than]),
            (4, [.ngo, .mui, .hoi, .suu], [.ty, .dau, .tySnake, .mao], [.dan, .thin, .than, .tuat]),
            (5, [.than, .dau, .suu, .mao], [.dan, .hoi, .mui, .tySnake], [.ty, .thin, .ngo, .tuat]),
            (6, [.tuat, .hoi, .mao, .tySnake], [.thin, .suu, .dau, .mui], [.ty, .dan, .ngo, .than])
        ]

        for (month, auspicious, inauspicious, ordinary) in expectations {
            assertClassification(.auspicious, branches: auspicious, lunarMonth: month)
            assertClassification(.inauspicious, branches: inauspicious, lunarMonth: month)
            assertClassification(.ordinary, branches: ordinary, lunarMonth: month)

            let allBranches = Set(auspicious + inauspicious + ordinary)
            XCTAssertEqual(allBranches, Set(EarthlyBranch.allCases))
            XCTAssertEqual(allBranches.count, 12)
        }
    }

    func testMonthPairsShareTheSameClassification() {
        for lunarMonth in 1...6 {
            for dayBranch in EarthlyBranch.allCases {
                XCTAssertEqual(
                    TraditionalDayClassifier.classification(
                        lunarMonth: lunarMonth,
                        dayBranch: dayBranch
                    ),
                    TraditionalDayClassifier.classification(
                        lunarMonth: lunarMonth + 6,
                        dayBranch: dayBranch
                    )
                )
            }
        }
    }

    func testCivilDateUsesTheCanonicalDayBranch() throws {
        let solarDate = try SolarDate(validatingYear: 2004, month: 4, day: 19)
        let lunarDate = try LunarDate(
            validatingYear: 2004,
            month: 3,
            day: 1,
            isLeapMonth: false
        )

        XCTAssertEqual(CanChiCalculator().day(for: solarDate).branch, .thin)
        XCTAssertEqual(
            TraditionalDayClassifier.classification(
                for: lunarDate,
                solarDate: solarDate
            ),
            .auspicious
        )
    }

    private func assertClassification(
        _ expected: TraditionalDayClassification,
        branches: [EarthlyBranch],
        lunarMonth: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for branch in branches {
            XCTAssertEqual(
                TraditionalDayClassifier.classification(
                    lunarMonth: lunarMonth,
                    dayBranch: branch
                ),
                expected,
                file: file,
                line: line
            )
        }
    }
}
