import ServiceManagement
import XCTest
@testable import VietLunarInfrastructure

final class SMLoginItemServiceTests: XCTestCase {
    func testTemporaryBundleCannotRegisterButCanRemoveStaleRegistration() throws {
        let registration = TestRegistration()
        registration.status = .enabled
        let service = SMLoginItemService(registration: registration, bundleURL: URL(
            fileURLWithPath: "/private/var/folders/test/AppTranslocation/session/d/VietLunar.app"
        ))
        XCTAssertEqual(service.status(), .enabled)
        XCTAssertThrowsError(try service.setEnabled(true))
        XCTAssertEqual(registration.registrations, 0)
        try service.setEnabled(false)
        XCTAssertEqual(registration.unregistrations, 1)
        XCTAssertEqual(service.status(), .disabled)
    }

    func testInstalledAppRegistersAndUnregistersIdempotently() throws {
        let registration = TestRegistration()
        let service = SMLoginItemService(registration: registration, bundleURL: URL(
            fileURLWithPath: "/Applications/VietLunar.app"
        ))
        XCTAssertEqual(service.status(), .disabled)
        try service.setEnabled(true)
        try service.setEnabled(true)
        XCTAssertEqual(service.status(), .enabled)
        XCTAssertEqual(registration.registrations, 1)
        try service.setEnabled(false)
        try service.setEnabled(false)
        XCTAssertEqual(service.status(), .disabled)
        XCTAssertEqual(registration.unregistrations, 1)
    }

    func testMissingRegistrationCanBeRetried() throws {
        let registration = TestRegistration()
        registration.status = .notFound
        let service = SMLoginItemService(registration: registration, bundleURL: URL(
            fileURLWithPath: "/Users/test/Applications/VietLunar.app"
        ))
        try service.setEnabled(true)
        XCTAssertEqual(service.status(), .enabled)
    }

    func testUserApprovalIsNeverBypassedByRegisteringAgain() throws {
        let registration = TestRegistration()
        registration.status = .requiresApproval
        let service = SMLoginItemService(registration: registration, bundleURL: URL(
            fileURLWithPath: "/Applications/VietLunar.app"
        ))
        try service.setEnabled(true)
        XCTAssertEqual(service.status(), .requiresUserApproval)
        XCTAssertEqual(registration.registrations, 0)
        XCTAssertEqual(registration.unregistrations, 0)
    }
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

private final class TestRegistration: LoginItemRegistering {
    var status: SMAppService.Status = .notRegistered
    var registrations = 0
    var unregistrations = 0
    func register() throws { registrations += 1; status = .enabled }
    func unregister() throws { unregistrations += 1; status = .notRegistered }
}
