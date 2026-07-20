import XCTest

final class VietLunarUITests: XCTestCase {
    @MainActor
    func testApplicationLaunches() {
        let application = makeApplication()
        application.launch()
        XCTAssertTrue(application.wait(for: .runningBackground, timeout: 5))
        application.terminate()
    }

    @MainActor
    func testMenuBarPopoverNavigationTodayAndSettingsFlow() throws {
        let application = makeApplication()
        application.launch()
        defer { application.terminate() }

        try openPopover(for: application)

        XCTAssertTrue(application.staticTexts["today-header"].waitForExistence(timeout: 3))

        let monthTitle = application.staticTexts["visible-month-title"]
        XCTAssertTrue(monthTitle.exists)
        let originalMonth = try XCTUnwrap(textValue(of: monthTitle))

        let nextMonth = application.buttons["next-month-button"]
        XCTAssertTrue(nextMonth.isEnabled)
        nextMonth.click()
        XCTAssertTrue(waitUntil(timeout: 3) { textValue(of: monthTitle) != originalMonth })

        application.buttons["today-button"].click()
        XCTAssertTrue(waitUntil(timeout: 3) { textValue(of: monthTitle) == originalMonth })

        let todayCell = application.buttons[todayCellIdentifier()]
        XCTAssertTrue(todayCell.exists)
        XCTAssertTrue(todayCell.label.contains("âm lịch"))
        XCTAssertTrue(
            ((todayCell.value as? String) ?? "").lowercased().contains("hôm nay")
        )

        application.buttons["settings-button"].click()
        XCTAssertTrue(
            application.staticTexts["settings-title"].waitForExistence(timeout: 3)
        )

        XCTAssertTrue(
            application.descendants(matching: .any)["title-format-picker"].exists
        )
        XCTAssertTrue(
            application.descendants(matching: .any)["week-start-picker"].exists
        )

        let clockToggle = application.descendants(matching: .any)["show-clock-toggle"]
        let titlePreview = application.staticTexts["menu-title-preview"]
        XCTAssertTrue(clockToggle.exists)
        XCTAssertTrue(titlePreview.exists)
        XCTAssertFalse(textValue(of: titlePreview)?.contains(":") ?? true)

        clockToggle.click()
        XCTAssertTrue(
            waitUntil(timeout: 3) {
                textValue(of: titlePreview)?.contains(":") == true
            }
        )
        XCTAssertTrue(
            application.descendants(matching: .any)["use-24-hour-toggle"].isEnabled
        )

        clockToggle.click()
        XCTAssertTrue(
            waitUntil(timeout: 3) {
                textValue(of: titlePreview)?.contains(":") == false
            }
        )
    }

    @MainActor
    private func makeApplication() -> XCUIApplication {
        let application = XCUIApplication()
        application.launchEnvironment["VIETLUNAR_TEST_PREFERENCES_SUITE"] =
            "VietLunarUITests.\(UUID().uuidString)"
        return application
    }

    @MainActor
    private func openPopover(for application: XCUIApplication) throws {
        let appStatusItem = application.descendants(matching: .statusItem).firstMatch

        if appStatusItem.waitForExistence(timeout: 3) {
            appStatusItem.click()
            return
        }

        let systemUIServer = XCUIApplication(bundleIdentifier: "com.apple.systemuiserver")
        let systemStatusItem = systemUIServer.descendants(matching: .statusItem).firstMatch
        XCTAssertTrue(
            systemStatusItem.waitForExistence(timeout: 3),
            "Không tìm thấy VietLunar status item trong accessibility tree"
        )
        systemStatusItem.click()
    }

    @MainActor
    private func waitUntil(
        timeout: TimeInterval,
        condition: () -> Bool
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return condition()
    }

    @MainActor
    private func textValue(of element: XCUIElement) -> String? {
        if let value = element.value as? String, !value.isEmpty {
            return value
        }
        return element.label.isEmpty ? nil : element.label
    }

    @MainActor
    private func todayCellIdentifier() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 7 * 60 * 60) ?? .gmt
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return "day-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
