import XCTest
@testable import VietLunarCore

/// Validates the bundled calendar and known data regressions. Update the dated
/// regression fixtures when refreshing the bundled calendar for a new year.
final class BundledHolidayCalendarTests: XCTestCase {
    func testBundledDefaultCalendarParsesAndHasOfficialHolidays() throws {
        let calendar = try loadCalendar()

        XCTAssertTrue(calendar.events.contains { $0.kind == .official })
        let range = try XCTUnwrap(calendar.yearRange)
        XCTAssertTrue(ICSHolidayParser.supportedYears.contains(range.lowerBound))
        XCTAssertTrue(ICSHolidayParser.supportedYears.contains(range.upperBound))
    }

    func testTetBreakDoesNotLabelFollowingDaysAsNewYearsEve() throws {
        let index = HolidayIndex(calendar: try loadCalendar())
        for day in 16...20 {
            let date = try SolarDate(validatingYear: 2026, month: 2, day: day)
            let holidays = index.occurrences(on: date)
            let holiday = try XCTUnwrap(holidays.first { $0.name == "Nghỉ Tết Nguyên Đán" })
            XCTAssertEqual(holiday.dayNumber, day - 15)
            XCTAssertEqual(holiday.dayCount, 5)
            XCTAssertFalse(holidays.contains { $0.name.contains("Giao thừa") })
        }
        let newYear = try SolarDate(validatingYear: 2026, month: 2, day: 17)
        XCTAssertTrue(index.occurrences(on: newYear).contains { $0.name == "Tết Nguyên Đán" })
    }

    private func loadCalendar() throws -> HolidayCalendar {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // CoreTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repository root
            .appendingPathComponent("App/Resources/Holidays/vietnam.ics")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: url.path),
            "The default holiday calendar must stay at App/Resources/Holidays/vietnam.ics"
        )

        return try ICSHolidayParser.parse(Data(contentsOf: url))
    }
}
