import XCTest
@testable import VietLunarCore

/// Validate the actual bundled artifact, including every lunar holiday against
/// the independent lookup table used by the app.
final class BundledHolidayCalendarTests: XCTestCase {
    func testBundledCalendarCoversEveryYearFrom2000Through2050() throws {
        let calendar = try loadCalendar()
        XCTAssertEqual(calendar.yearRange, 2000...2050)
        XCTAssertEqual(calendar.events.count, 2116)
        for year in 2000...2050 {
            let events = calendar.events.filter { $0.firstDate.year == year }
            XCTAssertEqual(events.count, year < 2026 ? 41 : 42, "Year \(year)")
            XCTAssertEqual(events.filter { $0.kind == .official }.count, year < 2026 ? 6 : 7)
            XCTAssertEqual(events.filter { $0.kind == .observance }.count, 35)
            XCTAssertTrue(events.allSatisfy { $0.dayCount == 1 })
            XCTAssertEqual(Set(events).count, events.count)
        }
    }

    func testEveryLunarHolidayMatchesAppCalendarAndNeverRepeatsInLeapMonth() throws {
        let calendar = try loadCalendar()
        let engine = LunarCalendarEngine()
        let lunarRules: [(String, Int, Int)] = [
            ("Tết Nguyên đán", 1, 1), ("Giỗ Tổ Hùng Vương", 3, 10),
            ("Chiến thắng Ngọc Hồi – Đống Đa", 1, 5), ("Tết Nguyên tiêu", 1, 15),
            ("Tết Hàn thực", 3, 3), ("Đại lễ Phật đản", 4, 15),
            ("Tết Đoan ngọ", 5, 5), ("Rằm tháng Bảy – Lễ Vu lan", 7, 15),
            ("Tết Trung thu", 8, 15), ("Tết ông Công, ông Táo", 12, 23)
        ]
        for year in 2000...2050 {
            for (name, month, day) in lunarRules {
                let events = calendar.events.filter { $0.firstDate.year == year && $0.name == name }
                XCTAssertEqual(events.count, 1, "\(year): \(name)")
                let event = try XCTUnwrap(events.first)
                let lunar = try engine.lunarDate(for: event.firstDate)
                XCTAssertEqual(lunar.month, month, "\(event.firstDate): \(name)")
                XCTAssertEqual(lunar.day, day, "\(event.firstDate): \(name)")
                XCTAssertFalse(lunar.isLeapMonth, "\(event.firstDate): \(name)")
            }
        }
    }

    func testEveIsOneObservanceAndNoGenericFiveDayBreakIsProjected() throws {
        let calendar = try loadCalendar()
        let index = HolidayIndex(calendar: calendar)
        for year in 2000...2050 {
            let tet = try XCTUnwrap(calendar.events.first { $0.firstDate.year == year && $0.name == "Tết Nguyên đán" })
            let eve = try GregorianJDN.solarDate(forJDN: GregorianJDN.jdn(for: tet.firstDate) - 1)
            let events = index.occurrences(on: eve)
            XCTAssertTrue(events.contains { $0.name == "Giao thừa tết Nguyên đán" && $0.kind == .observance && $0.dayCount == 1 })
            XCTAssertFalse(index.occurrences(on: tet.firstDate).contains { $0.name.contains("Giao thừa") })
        }
        XCTAssertFalse(calendar.events.contains { $0.name.contains("Kỳ nghỉ") || $0.name.contains("Nghỉ Tết") })
    }

    func testKnownDatesClassificationsAndEffectiveDates() throws {
        let index = HolidayIndex(calendar: try loadCalendar())
        for (year, month, day, name) in [
            (2026, 2, 17, "Tết Nguyên đán"), (2027, 2, 6, "Tết Nguyên đán"),
            (2028, 1, 26, "Tết Nguyên đán"), (2026, 4, 26, "Giỗ Tổ Hùng Vương")
        ] {
            let date = try SolarDate(validatingYear: year, month: month, day: day)
            XCTAssertTrue(index.occurrences(on: date).contains { $0.name == name && $0.kind == .official })
        }
        for year in 2000...2050 {
            let cultureDay = try SolarDate(validatingYear: year, month: 11, day: 24)
            XCTAssertEqual(index.isOfficialHoliday(on: cultureDay), year >= 2026)
            let teachersDay = try SolarDate(validatingYear: year, month: 11, day: 20)
            XCTAssertEqual(index.occurrences(on: teachersDay).map(\.kind), [.observance])
            let bookDay = try SolarDate(validatingYear: year, month: 4, day: 21)
            XCTAssertTrue(index.occurrences(on: bookDay).contains {
                $0.name == (year < 2022 ? "Ngày Sách Việt Nam" : "Ngày Sách và Văn hóa đọc Việt Nam")
            })
        }
        for year in [1999, 2051] {
            XCTAssertTrue(index.occurrences(on: try SolarDate(validatingYear: year, month: 1, day: 1)).isEmpty)
        }
    }

    private func loadCalendar() throws -> HolidayCalendar {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("App/Resources/Holidays/vietnam.ics")
        let data = try Data(contentsOf: url)
        XCTAssertLessThan(data.count, ICSHolidayParser.maximumByteCount)
        return try ICSHolidayParser.parse(data)
    }
}
