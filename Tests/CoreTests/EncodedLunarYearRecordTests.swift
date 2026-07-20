import XCTest
@testable import VietLunarCore

final class EncodedLunarYearRecordTests: XCTestCase {
    func testCommonYearMapsTwelveLogicalMonths() throws {
        let record = try record(for: 2024)
        XCTAssertEqual(record.leapMonth, 0)
        XCTAssertEqual(record.monthCount, 12)

        for index in 0..<12 {
            let logical = try record.logicalMonth(atSequentialIndex: index)
            XCTAssertEqual(logical.month, index + 1)
            XCTAssertFalse(logical.isLeap)
            XCTAssertEqual(
                try record.sequentialIndex(month: logical.month, isLeap: false),
                index
            )
        }
    }

    func testLeapMonthTwoIn2004MapsImmediatelyAfterNormalMonth() throws {
        let record = try record(for: 2004)
        XCTAssertEqual(record.leapMonth, 2)
        XCTAssertEqual(record.monthCount, 13)

        let normalMonth = try record.logicalMonth(atSequentialIndex: 1)
        XCTAssertEqual(normalMonth.month, 2)
        XCTAssertFalse(normalMonth.isLeap)

        let leapMonth = try record.logicalMonth(atSequentialIndex: 2)
        XCTAssertEqual(leapMonth.month, 2)
        XCTAssertTrue(leapMonth.isLeap)
        XCTAssertEqual(try record.monthLength(atSequentialIndex: 2), 29)

        let followingMonth = try record.logicalMonth(atSequentialIndex: 3)
        XCTAssertEqual(followingMonth.month, 3)
        XCTAssertFalse(followingMonth.isLeap)
    }

    func testLeapMonthSixIn2025MapsBothDirections() throws {
        let record = try record(for: 2025)
        XCTAssertEqual(record.leapMonth, 6)
        XCTAssertEqual(try record.sequentialIndex(month: 6, isLeap: false), 5)
        XCTAssertEqual(try record.sequentialIndex(month: 6, isLeap: true), 6)
        XCTAssertEqual(try record.sequentialIndex(month: 7, isLeap: false), 7)
    }

    func testInvalidLeapFlagAndIndexThrowTypedErrors() throws {
        let record = try record(for: 2024)
        XCTAssertThrowsError(try record.sequentialIndex(month: 2, isLeap: true)) { error in
            XCTAssertEqual(
                error as? LunarYearRecordError,
                .invalidLogicalMonth(month: 2, isLeap: true, actualLeapMonth: nil)
            )
        }
        XCTAssertThrowsError(try record.monthLength(atSequentialIndex: 12)) { error in
            XCTAssertEqual(
                error as? LunarYearRecordError,
                .invalidSequentialIndex(12, monthCount: 12)
            )
        }
    }

    func testRecordInitializerRejectsBitsOutsideMonthCount() {
        XCTAssertThrowsError(
            try EncodedLunarYearRecord(
                validatingYear: 2024,
                tetJDN: 2_460_350,
                leapMonth: 0,
                monthLengthBits: UInt16(1) << 12
            )
        )
    }

    private func record(for year: Int) throws -> EncodedLunarYearRecord {
        let index = year - GeneratedLunarYearTableData.firstYear
        return try XCTUnwrap(GeneratedLunarYearTableData.records[safe: index])
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
