import XCTest
@testable import VietLunarCore

final class VietnameseCalendarFormatterTests: XCTestCase {
    private let calculator = CanChiCalculator()

    func testCompactMenuTitlesUseTwoDigitsAndLeapMarker() throws {
        let normal = try LunarDate(
            validatingYear: 2026,
            month: 6,
            day: 7,
            isLeapMonth: false
        )
        let leap = try LunarDate(
            validatingYear: 2025,
            month: 6,
            day: 25,
            isLeapMonth: true
        )

        XCTAssertEqual(VietnameseCalendarFormatter.compactMenuTitle(for: normal), "07/06 ÂL")
        XCTAssertEqual(VietnameseCalendarFormatter.compactMenuTitle(for: leap), "25/06N ÂL")
    }

    func testFullGregorianDateUsesExactVietnameseWeekdayAndDiacritics() throws {
        let solarDate = try SolarDate(validatingYear: 2026, month: 7, day: 20)

        XCTAssertEqual(
            VietnameseCalendarFormatter.fullGregorianDate(solarDate),
            "Thứ Hai, 20 tháng 7 năm 2026"
        )
        XCTAssertEqual(VietnameseCalendarFormatter.compactSolarDate(solarDate), "20/07")
    }

    func testEveryVietnameseWeekdayNameIsStable() throws {
        let firstMondayJDN = GregorianJDN.jdn(
            for: try SolarDate(validatingYear: 2026, month: 7, day: 20)
        )
        let expected = [
            "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm",
            "Thứ Sáu", "Thứ Bảy", "Chủ Nhật"
        ]

        for offset in 0..<7 {
            let date = try GregorianJDN.solarDate(forJDN: firstMondayJDN + offset)
            XCTAssertEqual(VietnameseCalendarFormatter.weekdayName(for: date), expected[offset])
        }
    }

    func testFullLunarDateDistinguishesNormalAndLeapMonths() throws {
        let normal = try LunarDate(
            validatingYear: 2026,
            month: 6,
            day: 7,
            isLeapMonth: false
        )
        let leap = try LunarDate(
            validatingYear: 2025,
            month: 6,
            day: 25,
            isLeapMonth: true
        )

        XCTAssertEqual(
            VietnameseCalendarFormatter.fullLunarDate(
                normal,
                yearCanChi: calculator.year(forLunarYear: normal.year)
            ),
            "Ngày 7 tháng 6 âm lịch, năm Bính Ngọ"
        )
        XCTAssertEqual(
            VietnameseCalendarFormatter.fullLunarDate(
                leap,
                yearCanChi: calculator.year(forLunarYear: leap.year)
            ),
            "Ngày 25 tháng 6 nhuận âm lịch, năm Ất Tỵ"
        )
    }

    func testCanChiAndMonthGridLabelsPreserveVietnameseText() throws {
        XCTAssertEqual(
            VietnameseCalendarFormatter.canChi(
                StemBranch(stem: .at, branch: .tySnake)
            ),
            "Ất Tỵ"
        )

        let ordinaryDay = try LunarDate(
            validatingYear: 2026,
            month: 6,
            day: 7,
            isLeapMonth: false
        )
        let firstLeapDay = try LunarDate(
            validatingYear: 2025,
            month: 6,
            day: 1,
            isLeapMonth: true
        )
        XCTAssertEqual(VietnameseCalendarFormatter.monthGridLunarLabel(ordinaryDay), "7")
        XCTAssertEqual(VietnameseCalendarFormatter.monthGridLunarLabel(firstLeapDay), "1/6N")
    }

    func testCellAccessibilityLabelMatchesVietnameseProductCopy() throws {
        let solarDate = try SolarDate(validatingYear: 2026, month: 7, day: 20)
        let lunarDate = try LunarDate(
            validatingYear: 2026,
            month: 6,
            day: 7,
            isLeapMonth: false
        )
        let cell = MonthGridCell(
            solarDate: solarDate,
            lunarDate: lunarDate,
            isInDisplayedMonth: true,
            isToday: true
        )

        XCTAssertEqual(
            VietnameseCalendarFormatter.cellAccessibilityLabel(
                for: cell,
                yearCanChi: calculator.year(forLunarYear: lunarDate.year)
            ),
            "Thứ Hai, ngày 20 tháng 7 năm 2026; ngày 7 tháng 6 âm lịch, năm Bính Ngọ; hôm nay."
        )
    }
}
