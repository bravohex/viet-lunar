import XCTest
@testable import VietLunarCore

/// Guards the file shipped as the default holiday calendar without depending
/// on which year or holidays it lists, so refreshing it stays a data-only change.
final class BundledHolidayCalendarTests: XCTestCase {
    func testBundledDefaultCalendarParsesAndHasOfficialHolidays() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // CoreTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repository root
            .appendingPathComponent("App/Resources/Holidays/vietnam.ics")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: url.path),
            "The default holiday calendar must stay at App/Resources/Holidays/vietnam.ics"
        )

        let calendar = try ICSHolidayParser.parse(Data(contentsOf: url))

        XCTAssertTrue(calendar.events.contains { $0.kind == .official })
        let range = try XCTUnwrap(calendar.yearRange)
        XCTAssertTrue(ICSHolidayParser.supportedYears.contains(range.lowerBound))
        XCTAssertTrue(ICSHolidayParser.supportedYears.contains(range.upperBound))
    }
}
