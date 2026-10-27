import XCTest
@testable import VietLunarCore

final class MonthGridBuilderTests: XCTestCase {
    private let engine = LunarCalendarEngine()

    func testGridAlwaysContainsFortyTwoUniqueConsecutiveDates() throws {
        let cells = try build(year: 2026, month: 7, weekStart: .monday, todayDay: 20)

        XCTAssertEqual(cells.count, MonthGridBuilder.cellCount)
        XCTAssertEqual(Set(cells.map(\.solarDate)).count, MonthGridBuilder.cellCount)
        XCTAssertEqual(cells.first?.solarDate, try solarDate(2026, 6, 29))
        XCTAssertEqual(cells.last?.solarDate, try solarDate(2026, 8, 9))

        for pair in zip(cells, cells.dropFirst()) {
            XCTAssertEqual(
                GregorianJDN.jdn(for: pair.1.solarDate),
                GregorianJDN.jdn(for: pair.0.solarDate) + 1
            )
        }
    }

    func testMondayGridOffsetsForMonthsBeginningEveryWeekday() throws {
        let cases: [(Int, Int, SolarDate)] = [
            (2023, 5, try solarDate(2023, 5, 1)), // Monday
            (2023, 8, try solarDate(2023, 7, 31)), // Tuesday
            (2023, 2, try solarDate(2023, 1, 30)), // Wednesday
            (2023, 6, try solarDate(2023, 5, 29)), // Thursday
            (2023, 9, try solarDate(2023, 8, 28)), // Friday
            (2023, 4, try solarDate(2023, 3, 27)), // Saturday
            (2023, 1, try solarDate(2022, 12, 26)) // Sunday
        ]

        for (year, month, expectedFirstDate) in cases {
            let cells = try build(
                year: year,
                month: month,
                weekStart: .monday,
                todayDay: 15
            )
            XCTAssertEqual(cells.first?.solarDate, expectedFirstDate)
        }
    }

    func testMondayAndSundayWeekStartsShiftGridStart() throws {
        let mondayCells = try build(year: 2026, month: 7, weekStart: .monday, todayDay: 20)
        let sundayCells = try build(year: 2026, month: 7, weekStart: .sunday, todayDay: 20)

        XCTAssertEqual(mondayCells.first?.solarDate, try solarDate(2026, 6, 29))
        XCTAssertEqual(sundayCells.first?.solarDate, try solarDate(2026, 6, 28))
    }

    func testCommonAndLeapFebruaryHaveCorrectInMonthDayCounts() throws {
        let commonYear = try build(year: 2023, month: 2, weekStart: .monday, todayDay: 1)
        let leapYear = try build(year: 2024, month: 2, weekStart: .monday, todayDay: 1)

        XCTAssertEqual(commonYear.filter(\.isInDisplayedMonth).count, 28)
        XCTAssertEqual(leapYear.filter(\.isInDisplayedMonth).count, 29)
    }

    func testTodayFlagAppearsExactlyOnce() throws {
        let cells = try build(year: 2026, month: 7, weekStart: .monday, todayDay: 20)

        XCTAssertEqual(cells.filter(\.isToday).count, 1)
        XCTAssertEqual(cells.first(where: \.isToday)?.solarDate, try solarDate(2026, 7, 20))
    }

    func testGridSpansLunarYearBoundary() throws {
        let cells = try build(year: 1984, month: 2, weekStart: .monday, todayDay: 2)
        let beforeTetDate = try solarDate(1984, 2, 1)
        let tetDate = try solarDate(1984, 2, 2)
        let beforeTet = try XCTUnwrap(cells.first { $0.solarDate == beforeTetDate })
        let tet = try XCTUnwrap(cells.first { $0.solarDate == tetDate })

        XCTAssertEqual(beforeTet.lunarDate.year, 1983)
        XCTAssertEqual(beforeTet.lunarDate.month, 12)
        XCTAssertEqual(beforeTet.lunarDate.day, 30)
        XCTAssertEqual(tet.lunarDate.year, 1984)
        XCTAssertEqual(tet.lunarDate.month, 1)
        XCTAssertEqual(tet.lunarDate.day, 1)
    }

    func testGridSpansLeapLunarMonthBoundary() throws {
        let cells = try build(year: 2004, month: 3, weekStart: .monday, todayDay: 21)
        let leapMonthStartDate = try solarDate(2004, 3, 21)
        let leapMonthStart = try XCTUnwrap(cells.first {
            $0.solarDate == leapMonthStartDate
        })

        XCTAssertEqual(leapMonthStart.lunarDate.month, 2)
        XCTAssertEqual(leapMonthStart.lunarDate.day, 1)
        XCTAssertTrue(leapMonthStart.lunarDate.isLeapMonth)
    }

    func testBoundaryMonthsContainEverySupportedDay() throws {
        for weekStart in WeekStart.allCases {
            for (year, month) in [(1800, 1), (2199, 12)] {
                let cells = try build(year: year, month: month, weekStart: weekStart, todayDay: 1)
                XCTAssertEqual(cells.filter(\.isInDisplayedMonth).count, 31)
                XCTAssertTrue(cells.allSatisfy { engine.supportedSolarRange.contains($0.solarDate) })
                XCTAssertEqual(cells.filter(\.isToday).count, 1)
            }
        }
    }

    func testOutsideMonthsRemainUnsupportedEvenWhenPaddingOverlapsRange() {
        XCTAssertThrowsError(try build(year: 1799, month: 12, weekStart: .monday, todayDay: 1))
        XCTAssertThrowsError(try build(year: 2200, month: 1, weekStart: .monday, todayDay: 1))
    }

    private func build(
        year: Int,
        month: Int,
        weekStart: WeekStart,
        todayDay: Int
    ) throws -> [MonthGridCell] {
        try MonthGridBuilder(lunarEngine: engine).build(
            displayedMonth: YearMonth(validatingYear: year, month: month),
            weekStart: weekStart,
            today: SolarDate(validatingYear: year, month: month, day: todayDay)
        )
    }

    private func solarDate(_ year: Int, _ month: Int, _ day: Int) throws -> SolarDate {
        try SolarDate(validatingYear: year, month: month, day: day)
    }
}
