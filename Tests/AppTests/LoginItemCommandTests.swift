import VietLunarInfrastructure
import XCTest

final class LoginItemCommandTests: XCTestCase {
    func testTemporaryAppCanSuccessfullyRemoveOldRegistration() {
        let service = TestLoginService()
        service.requiresInstallation = true
        service.currentStatus = .enabled
        let result = LoginItemCommand.disable.execute(using: service)
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(service.currentStatus, .disabled)
    }
    func testPendingApprovalDoesNotReportEnableSucceeded() {
        let result = LoginItemCommand.enable.execute(using: PendingApprovalService())
        XCTAssertNotEqual(result.exitCode, 0)
        XCTAssertTrue(result.message.contains("requires approval"))
    }

    func testStatusDoesNotMutateRegistration() {
        let service = TestLoginService()
        service.currentStatus = .requiresUserApproval
        let result = LoginItemCommand.status.execute(using: service)
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(service.currentStatus, .requiresUserApproval)
        XCTAssertTrue(result.message.contains("requires approval"))
    }

    func testEnableDisableAndFailureAreReportedTruthfully() {
        let service = TestLoginService()
        XCTAssertEqual(LoginItemCommand.enable.execute(using: service).exitCode, 0)
        XCTAssertEqual(service.currentStatus, .enabled)
        service.failure = NSError(domain: "Test", code: 1)
        XCTAssertNotEqual(LoginItemCommand.disable.execute(using: service).exitCode, 0)
        XCTAssertEqual(service.currentStatus, .enabled)
        service.failure = nil
        XCTAssertEqual(LoginItemCommand.disable.execute(using: service).exitCode, 0)
        XCTAssertEqual(service.currentStatus, .disabled)
    }
}

private struct PendingApprovalService: LoginItemServicing {
    func status() -> LoginItemStatus { .requiresUserApproval }
    func setEnabled(_ enabled: Bool) throws {}
    func openSystemSettings() {}
}
