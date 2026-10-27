import XCTest
@testable import VietLunarCore

final class LunarExhaustiveRoundTripTests: XCTestCase {
    private let engine = LunarCalendarEngine()

    func testEveryReferenceRowIsValidAndMatchesRuntimeTable() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent(
            "ReferenceData/vietnam-lunar-1800-2199.reference.json"
        ))
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let rows = try XCTUnwrap(payload["rows"] as? [[Int]])
        XCTAssertEqual(rows.count, 146_097)
        let lowerJDN = GregorianJDN.jdn(for: engine.supportedSolarRange.lowerBound)
        for (offset, row) in rows.enumerated() {
            guard row.count == 5, row[0] == lowerJDN + offset,
                  (1...30).contains(row[3]), (0...1).contains(row[4]) else {
                return XCTFail("Invalid reference row at offset \(offset): \(row)")
            }
            let solar = try GregorianJDN.solarDate(forJDN: row[0])
            let reference = try LunarDate(
                validatingYear: row[1], month: row[2], day: row[3], isLeapMonth: row[4] == 1
            )
            let actual = try engine.lunarDate(for: solar)
            guard actual == reference else {
                return XCTFail("Reference mismatch for \(solar): \(reference) vs \(actual)")
            }
        }
    }

    func testEverySupportedSolarDateRoundTripsThroughLunarDate() throws {
        let lowerJDN = GregorianJDN.jdn(for: engine.supportedSolarRange.lowerBound)
        let upperJDN = GregorianJDN.jdn(for: engine.supportedSolarRange.upperBound)
        var checkedDateCount = 0

        for jdn in lowerJDN...upperJDN {
            let solarDate = try GregorianJDN.solarDate(forJDN: jdn)
            let lunarDate = try engine.lunarDate(for: solarDate)
            let recoveredSolarDate = try engine.solarDate(for: lunarDate)
            guard recoveredSolarDate == solarDate else {
                return XCTFail(
                    "Solar round trip failed at \(solarDate): \(lunarDate) -> \(recoveredSolarDate)"
                )
            }
            checkedDateCount += 1
        }

        XCTAssertEqual(checkedDateCount, 146_097)
    }

    func testEverySupportedLunarDateRoundTripsThroughSolarDate() throws {
        var checkedDateCount = 0

        for record in GeneratedLunarYearTableData.records {
            for sequentialIndex in 0..<record.monthCount {
                let logicalMonth = try record.logicalMonth(
                    atSequentialIndex: sequentialIndex
                )
                let monthLength = try record.monthLength(
                    atSequentialIndex: sequentialIndex
                )

                for day in 1...monthLength {
                    let lunarDate = try LunarDate(
                        validatingYear: record.year,
                        month: logicalMonth.month,
                        day: day,
                        isLeapMonth: logicalMonth.isLeap
                    )

                    do {
                        let solarDate = try engine.solarDate(for: lunarDate)
                        let recoveredLunarDate = try engine.lunarDate(for: solarDate)
                        guard recoveredLunarDate == lunarDate else {
                            return XCTFail(
                                "Lunar round trip failed at \(lunarDate): \(solarDate) -> \(recoveredLunarDate)"
                            )
                        }
                        checkedDateCount += 1
                    } catch LunarCalendarError.unsupportedSolarDate(let solarDate) {
                        XCTAssertFalse(engine.supportedSolarRange.contains(solarDate))
                    }
                }
            }
        }

        XCTAssertEqual(checkedDateCount, 146_097)
    }
}
