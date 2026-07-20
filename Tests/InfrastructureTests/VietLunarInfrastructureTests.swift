import XCTest
@testable import VietLunarInfrastructure

final class VietLunarInfrastructureTests: XCTestCase {
    func testInfrastructureLinksCoreTarget() {
        XCTAssertEqual(InfrastructureBuildInfo.coreName, "VietLunarCore")
    }

    func testLoggingSubsystemIsStable() {
        XCTAssertEqual(AppLog.subsystem, "com.tuanlm.VietLunar")
    }
}
