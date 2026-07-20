import ServiceManagement
import XCTest
@testable import VietLunarInfrastructure

final class SMLoginItemServiceTests: XCTestCase {
    func testEveryKnownSystemStatusMapsToDomainStatus() {
        let cases: [(SMAppService.Status, LoginItemStatus)] = [
            (.notRegistered, .disabled),
            (.enabled, .enabled),
            (.requiresApproval, .requiresUserApproval),
            (.notFound, .unavailable)
        ]

        for (systemStatus, expected) in cases {
            XCTAssertEqual(
                SMLoginItemService.map(status: systemStatus),
                expected
            )
        }
    }
}
