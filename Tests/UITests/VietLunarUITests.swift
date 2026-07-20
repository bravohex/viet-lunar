import XCTest

final class VietLunarUITests: XCTestCase {
    @MainActor
    func testApplicationLaunches() {
        let application = XCUIApplication()
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 5))
        application.terminate()
    }
}
