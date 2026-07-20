import Foundation
import XCTest
@testable import VietLunarCore

final class CanChiCalculatorTests: XCTestCase {
    private let calculator = CanChiCalculator()

    func testCuratedGoldenVectors() throws {
        XCTAssertEqual(calculator.year(forLunarYear: 2004).description, "Giáp Thân")
        XCTAssertEqual(
            calculator.month(forLunarYear: 2004, month: 3).description,
            "Mậu Thìn"
        )

        let solarDate = try SolarDate(validatingYear: 2004, month: 4, day: 19)
        XCTAssertEqual(GregorianJDN.jdn(for: solarDate), 2_453_115)
        XCTAssertEqual(calculator.day(for: solarDate).description, "Mậu Thìn")
    }

    func testLeapMonthInheritsNormalMonthCanChi() throws {
        let normal = try LunarDate(
            validatingYear: 2004,
            month: 2,
            day: 1,
            isLeapMonth: false
        )
        let leap = try LunarDate(
            validatingYear: 2004,
            month: 2,
            day: 1,
            isLeapMonth: true
        )

        XCTAssertEqual(calculator.month(for: normal), calculator.month(for: leap))
    }

    func testEveryDayAdvancesAndSixtyDayCycleRepeats() throws {
        let firstJDN = GregorianJDN.jdn(
            for: try SolarDate(validatingYear: 1800, month: 1, day: 1)
        )
        let lastJDN = GregorianJDN.jdn(
            for: try SolarDate(validatingYear: 2199, month: 12, day: 31)
        )

        for jdn in firstJDN...lastJDN {
            let current = calculator.day(forJDN: jdn)
            let next = calculator.day(forJDN: jdn + 1)
            let repeated = calculator.day(forJDN: jdn + 60)

            XCTAssertEqual(next.stem.rawValue, (current.stem.rawValue + 1) % 10)
            XCTAssertEqual(next.branch.rawValue, (current.branch.rawValue + 1) % 12)
            XCTAssertEqual(repeated, current)
        }
    }

    func testFloorModNormalizesNegativeValues() {
        XCTAssertEqual(floorMod(-1, 10), 9)
        XCTAssertEqual(floorMod(-11, 10), 9)
        XCTAssertEqual(floorMod(11, 10), 1)
    }

    func testStemBranchCodableAndDescriptionAreStable() throws {
        let value = StemBranch(stem: .giap, branch: .than)
        let encoded = try JSONEncoder().encode(value)

        XCTAssertEqual(try JSONDecoder().decode(StemBranch.self, from: encoded), value)
        XCTAssertEqual(value.description, "Giáp Thân")
    }
}
