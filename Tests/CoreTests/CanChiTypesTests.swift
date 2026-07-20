import Foundation
import XCTest
@testable import VietLunarCore

final class CanChiTypesTests: XCTestCase {
    func testHeavenlyStemsHaveStableOrderAndVietnameseNames() {
        XCTAssertEqual(HeavenlyStem.allCases.map(\.rawValue), Array(0..<10))
        XCTAssertEqual(
            HeavenlyStem.allCases.map(\.vietnameseName),
            ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
        )
    }

    func testEarthlyBranchesHaveStableOrderAndVietnameseNames() {
        XCTAssertEqual(EarthlyBranch.allCases.map(\.rawValue), Array(0..<12))
        XCTAssertEqual(
            EarthlyBranch.allCases.map(\.vietnameseName),
            ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
        )
    }

    func testEnumCodableRepresentationUsesStableIntegerRawValues() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for stem in HeavenlyStem.allCases {
            XCTAssertEqual(String(decoding: try encoder.encode(stem), as: UTF8.self), String(stem.rawValue))
            XCTAssertEqual(try decoder.decode(HeavenlyStem.self, from: Data(String(stem.rawValue).utf8)), stem)
        }

        for branch in EarthlyBranch.allCases {
            XCTAssertEqual(String(decoding: try encoder.encode(branch), as: UTF8.self), String(branch.rawValue))
            XCTAssertEqual(try decoder.decode(EarthlyBranch.self, from: Data(String(branch.rawValue).utf8)), branch)
        }
    }

    func testEnumCodableRejectsUnknownRawValues() {
        XCTAssertThrowsError(try JSONDecoder().decode(HeavenlyStem.self, from: Data("10".utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(EarthlyBranch.self, from: Data("12".utf8)))
    }
}
