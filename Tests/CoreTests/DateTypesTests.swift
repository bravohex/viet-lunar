import Foundation
import XCTest
@testable import VietLunarCore

final class DateTypesTests: XCTestCase {
    func testGregorianLeapYearCenturyRules() throws {
        XCTAssertNotNil(SolarDate.valid(year: 2000, month: 2, day: 29))
        XCTAssertNil(SolarDate.valid(year: 1900, month: 2, day: 29))
        XCTAssertNotNil(SolarDate.valid(year: 2024, month: 2, day: 29))
        XCTAssertNil(SolarDate.valid(year: 2023, month: 2, day: 29))
    }

    func testSolarDateRejectsInvalidComponents() {
        XCTAssertNil(SolarDate.valid(year: 0, month: 1, day: 1))
        XCTAssertNil(SolarDate.valid(year: 2026, month: 0, day: 1))
        XCTAssertNil(SolarDate.valid(year: 2026, month: 13, day: 1))
        XCTAssertNil(SolarDate.valid(year: 2026, month: 4, day: 31))
        XCTAssertNil(SolarDate.valid(year: 2026, month: 1, day: 0))
    }

    func testDateAndMonthComparisonAcrossBoundaries() throws {
        let lastDay = try SolarDate(validatingYear: 2025, month: 12, day: 31)
        let firstDay = try SolarDate(validatingYear: 2026, month: 1, day: 1)
        XCTAssertLessThan(lastDay, firstDay)

        let december = try YearMonth(validatingYear: 2025, month: 12)
        let january = try YearMonth(validatingYear: 2026, month: 1)
        XCTAssertLessThan(december, january)
    }

    func testValueTypesRoundTripThroughCodable() throws {
        try assertRoundTrip(SolarDate(validatingYear: 2026, month: 7, day: 20))
        try assertRoundTrip(
            LunarDate(
                validatingYear: 2026,
                month: 6,
                day: 7,
                isLeapMonth: false
            )
        )
        try assertRoundTrip(YearMonth(validatingYear: 2026, month: 7))
        try assertRoundTrip(LocalTime(validatingHour: 23, minute: 59))
    }

    func testLunarDateAndLocalTimeRejectInvalidComponents() {
        XCTAssertNil(LunarDate.valid(year: 2026, month: 13, day: 1))
        XCTAssertNil(LunarDate.valid(year: 2026, month: 1, day: 31))
        XCTAssertNil(LocalTime.valid(hour: 24, minute: 0))
        XCTAssertNil(LocalTime.valid(hour: 23, minute: 60))
    }

    func testCodableCannotCreateInvalidSolarDate() {
        let invalid = Data(#"{"year":1900,"month":2,"day":29}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SolarDate.self, from: invalid))
    }

    private func assertRoundTrip<Value>(_ value: Value) throws
    where Value: Codable & Equatable {
        let encoded = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(Value.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
}
