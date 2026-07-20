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

    func testEveryMenuBarTitleFormatUsesLiveSnapshotValues() throws {
        let snapshot = try snapshot(at: "2026-07-20T05:00:00Z") // 12:00 UTC+7
        let cases: [(MenuBarTitleFormat, String?)] = [
            (.lunarDate, "07/06 ÂL"),
            (.solarAndLunar, "20/07 · 07/06 ÂL"),
            (.lunarAndDayCanChi, "07/06 · Ất Mùi"),
            (.solarLunarAndDayCanChi, "20/07 · 07/06 · Ất Mùi"),
            (.iconOnly, nil)
        ]

        for (format, expectedTitle) in cases {
            XCTAssertEqual(
                VietnameseCalendarFormatter.menuBarPresentation(
                    for: snapshot,
                    format: format
                ).title,
                expectedTitle
            )
        }
    }

    func testMenuBarAccessibilityLabelIsFullyExpandedVietnameseText() throws {
        let snapshot = try snapshot(at: "2026-07-20T05:00:00Z")

        XCTAssertEqual(
            VietnameseCalendarFormatter.menuBarAccessibilityLabel(for: snapshot),
            "VietLunar; Thứ Hai, ngày 20 tháng 7 năm 2026; ngày 7 tháng 6 âm lịch, năm Bính Ngọ; Can–Chi ngày Ất Mùi; Can–Chi giờ Nhâm Ngọ."
        )
    }

    func testMenuBarTitleFormatDefaultAndCodableValuesAreStable() throws {
        XCTAssertEqual(MenuBarTitleFormat.defaultValue, .lunarDate)

        for format in MenuBarTitleFormat.allCases {
            let encoded = try JSONEncoder().encode(format)
            XCTAssertEqual(
                try JSONDecoder().decode(MenuBarTitleFormat.self, from: encoded),
                format
            )
        }
    }

    private func snapshot(at value: String) throws -> CalendarSnapshot {
        let instant = try XCTUnwrap(ISO8601DateFormatter().date(from: value))
        return try CalendarSnapshotFactory(
            lunarEngine: LunarCalendarEngine(),
            clock: FixedClock(instant: instant)
        ).makeSnapshot()
    }
}
