import XCTest
@testable import VietLunarCore

final class VietLunarCoreTests: XCTestCase {
    func testCoreTargetIsDiscoverable() {
        XCTAssertEqual(CoreBuildInfo.name, "VietLunarCore")
    }

    func testVietnameseStringCatalogIsEmbedded() {
        XCTAssertTrue(CoreLocalization.hasVietnameseCatalog)
        XCTAssertEqual(
            CoreLocalization.text("weekday.monday", fallback: "missing"),
            "Thứ Hai"
        )
    }
}
