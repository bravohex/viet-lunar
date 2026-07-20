import XCTest
@testable import VietLunarCore

final class GregorianJDNTests: XCTestCase {
    func testKnownJulianDayNumbersUseDocumentedNoonConvention() throws {
        XCTAssertEqual(
            GregorianJDN.jdn(for: try SolarDate(validatingYear: 2000, month: 1, day: 1)),
            2_451_545
        )
        XCTAssertEqual(
            GregorianJDN.jdn(for: try SolarDate(validatingYear: 1970, month: 1, day: 1)),
            2_440_588
        )
        XCTAssertEqual(
            GregorianJDN.jdn(for: try SolarDate(validatingYear: 2004, month: 4, day: 19)),
            2_453_115
        )
    }

    func testEverySupportedProductionDateRoundTrips() throws {
        let lower = try SolarDate(validatingYear: 1800, month: 1, day: 1)
        let upper = try SolarDate(validatingYear: 2199, month: 12, day: 31)
        let lowerJDN = GregorianJDN.jdn(for: lower)
        let upperJDN = GregorianJDN.jdn(for: upper)

        for jdn in lowerJDN...upperJDN {
            let date = try GregorianJDN.solarDate(forJDN: jdn)
            XCTAssertEqual(GregorianJDN.jdn(for: date), jdn)
        }

        XCTAssertEqual(try GregorianJDN.solarDate(forJDN: lowerJDN), lower)
        XCTAssertEqual(try GregorianJDN.solarDate(forJDN: upperJDN), upper)
    }

    func testAdjacentCivilDatesDifferByOneJDN() throws {
        let pairs = [
            (
                try SolarDate(validatingYear: 1999, month: 12, day: 31),
                try SolarDate(validatingYear: 2000, month: 1, day: 1)
            ),
            (
                try SolarDate(validatingYear: 2000, month: 2, day: 28),
                try SolarDate(validatingYear: 2000, month: 2, day: 29)
            ),
            (
                try SolarDate(validatingYear: 2000, month: 2, day: 29),
                try SolarDate(validatingYear: 2000, month: 3, day: 1)
            ),
            (
                try SolarDate(validatingYear: 1900, month: 2, day: 28),
                try SolarDate(validatingYear: 1900, month: 3, day: 1)
            )
        ]

        for pair in pairs {
            XCTAssertEqual(
                GregorianJDN.jdn(for: pair.1) - GregorianJDN.jdn(for: pair.0),
                1
            )
        }
    }

    func testInvalidJDNThrowsTypedError() {
        XCTAssertThrowsError(try GregorianJDN.solarDate(forJDN: Int.min / 2)) { error in
            XCTAssertEqual(error as? GregorianJDNError, .invalidJDN(Int.min / 2))
        }
    }
}
