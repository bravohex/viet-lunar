import XCTest
@testable import VietLunarCore

final class VietLunarCoreTests: XCTestCase {
    func testCoreTargetIsDiscoverable() {
        XCTAssertEqual(CoreBuildInfo.name, "VietLunarCore")
    }
}
