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

        XCTAssertTrue(application.staticTexts["selected-gregorian-date"].waitForExistence(timeout: 3))
        XCTAssertFalse(application.staticTexts["holiday-source-summary"].exists)
        let saturdayHeader = application.staticTexts["weekday-header-7"]
        let sundayHeader = application.staticTexts["weekday-header-1"]
        XCTAssertTrue(saturdayHeader.exists)
        XCTAssertTrue(sundayHeader.exists)
        XCTAssertEqual(saturdayHeader.value as? String, "T7")
        XCTAssertEqual(sundayHeader.value as? String, "CN")

        let monthTitle = application.staticTexts["visible-month-title"]
        XCTAssertTrue(monthTitle.exists)
        let originalMonth = try XCTUnwrap(textValue(of: monthTitle))

        let nextMonth = application.buttons["next-month-button"]
        XCTAssertTrue(nextMonth.isEnabled)
        nextMonth.click()
        XCTAssertTrue(waitUntil(timeout: 3) { textValue(of: monthTitle) != originalMonth })
        XCTAssertFalse(
            application.staticTexts["selected-hour-can-chi"].exists
        )

        application.buttons["today-button"].click()
        XCTAssertTrue(waitUntil(timeout: 3) { textValue(of: monthTitle) == originalMonth })
        let canChiDetail = application.staticTexts["selected-can-chi"]
        XCTAssertTrue(canChiDetail.exists)
        let canChiText = try XCTUnwrap(textValue(of: canChiDetail))
        XCTAssertTrue(canChiText.contains("Năm"))
        XCTAssertTrue(canChiText.contains("Tháng"))
        XCTAssertTrue(canChiText.contains("Ngày"))
        let auspiciousHours = application.staticTexts["selected-auspicious-hours"]
        XCTAssertTrue(auspiciousHours.exists)
        let auspiciousHoursValue = try XCTUnwrap(auspiciousHours.value as? String)
        XCTAssertTrue(auspiciousHoursValue.contains("("))
        XCTAssertTrue(auspiciousHoursValue.contains("–"))
        XCTAssertTrue(application.staticTexts["selected-hour-can-chi"].exists)
        XCTAssertTrue(application.buttons["quit-button"].exists)

        let todayCell = application.buttons[todayCellIdentifier()]
        XCTAssertTrue(todayCell.exists)
        XCTAssertTrue(todayCell.label.contains("âm lịch"))
        XCTAssertTrue(
            ((todayCell.value as? String) ?? "").lowercased().contains("hôm nay")
        )
        let dayClassificationValue = (todayCell.value as? String) ?? ""
        XCTAssertTrue(
            ["Ngày hoàng đạo", "Ngày hắc đạo", "Ngày thường"].contains {
                dayClassificationValue.contains($0)
            },
            "Mỗi ô ngày phải công bố trạng thái hoàng đạo, hắc đạo hoặc thường cho VoiceOver"
        )
        assertContextualDayStatusLabels(
            in: application,
            dayCellValue: dayClassificationValue
        )

        application.buttons["settings-button"].click()
        XCTAssertTrue(
            application.descendants(matching: .any)["general-tab"].waitForExistence(timeout: 3)
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

        XCTAssertTrue(
            application.descendants(matching: .statusItem).firstMatch.exists
        )

        let aboutTab = application.descendants(matching: .any)["about-tab"]
        XCTAssertTrue(aboutTab.exists)
        aboutTab.click()
        XCTAssertTrue(application.staticTexts["about-version"].exists)
        XCTAssertTrue(application.staticTexts["historical-caveat"].exists)
        XCTAssertTrue(application.staticTexts["privacy-summary"].exists)
    }

    @MainActor
    func testSettingsPersistAfterRelaunch() throws {
        let application = makeApplication()
        application.launch()
        defer { application.terminate() }

        try openSettings(for: application)
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
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))

        application.terminate()
        application.launch()
        try openSettings(for: application)

        let relaunchedPreview = application.staticTexts["menu-title-preview"]
        XCTAssertTrue(
            waitUntil(timeout: 3) {
                textValue(of: relaunchedPreview)?.contains(":") == true
            },
            "Cài đặt đồng hồ phải được giữ sau khi khởi động lại ứng dụng"
        )
    }

    @MainActor
    func testImportedCalendarCanBeManagedCancelledAndDeleted() throws {
        let application = makeApplication()
        application.launchEnvironment["VIETLUNAR_TEST_HOLIDAY_ICS"] =
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nX-WR-CALNAME:UI Test Calendar\r\nBEGIN:VEVENT\r\nSUMMARY:Test Holiday\r\nDTSTART;VALUE=DATE:20260101\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"
        application.launch()
        application.launchEnvironment.removeValue(forKey: "VIETLUNAR_TEST_HOLIDAY_ICS")
        defer { application.terminate() }
        try openSettings(for: application)
        application.buttons["manage-holidays-button"].click()
        let remove = application.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "remove-holiday-source-")).firstMatch
        XCTAssertTrue(remove.waitForExistence(timeout: 3))
        remove.click()
        XCTAssertTrue(application.sheets["alert"].waitForExistence(timeout: 3))
        application.sheets["alert"].buttons["Hủy"].click()
        XCTAssertTrue(remove.exists)
        remove.click()
        application.sheets["alert"].buttons["Xóa"].click()
        XCTAssertTrue(application.staticTexts["imported-holidays-empty"].waitForExistence(timeout: 3))
        application.buttons["close-holiday-manager-button"].click()
        application.terminate()
        application.launch()
        try openSettings(for: application)
        application.buttons["manage-holidays-button"].click()
        XCTAssertTrue(application.staticTexts["imported-holidays-empty"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testPopoverPerformanceSignposts() {
        let launchWorkMetric = XCTOSSignpostMetric(
            subsystem: "com.bravohex.vietlunar",
            category: "PointsOfInterest",
            name: "Application App Work"
        )
        let firstOpenMetric = XCTOSSignpostMetric(
            subsystem: "com.bravohex.vietlunar",
            category: "PointsOfInterest",
            name: "Popover First Open"
        )
        let subsequentOpenMetric = XCTOSSignpostMetric(
            subsystem: "com.bravohex.vietlunar",
            category: "PointsOfInterest",
            name: "Popover Subsequent Open"
        )
        let options = XCTMeasureOptions()
        options.iterationCount = 3

        measure(
            metrics: [launchWorkMetric, firstOpenMetric, subsequentOpenMetric],
            options: options
        ) {
            let application = makeApplication()
            application.launch()
            defer { application.terminate() }

            let statusItem = application.descendants(
                matching: .statusItem
            ).firstMatch
            XCTAssertTrue(statusItem.waitForExistence(timeout: 3))

            statusItem.click()
            let todayHeader = application.staticTexts["selected-gregorian-date"]
            XCTAssertTrue(todayHeader.waitForExistence(timeout: 3))

            statusItem.click()
            XCTAssertTrue(todayHeader.waitForNonExistence(timeout: 3))

            statusItem.click()
            XCTAssertTrue(todayHeader.waitForExistence(timeout: 3))
        }
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
            application.activate()
            let header = application.staticTexts["selected-gregorian-date"]
            if !header.exists { appStatusItem.click() }
            // A transient popover can close when another desktop app takes focus.
            // Retry once only after verifying that it is actually closed.
            if !header.waitForExistence(timeout: 3) {
                application.activate()
                appStatusItem.click()
            }
            XCTAssertTrue(header.waitForExistence(timeout: 3))
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
    private func openSettings(for application: XCUIApplication) throws {
        try openPopover(for: application)
        let settingsButton = application.buttons["settings-button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.click()
        XCTAssertTrue(
            application.descendants(matching: .any)["general-tab"].waitForExistence(timeout: 3)
        )
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
    private func assertContextualDayStatusLabels(
        in application: XCUIApplication,
        dayCellValue: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectedStatus = ["Ngày hoàng đạo", "Ngày hắc đạo"].first {
            dayCellValue.contains($0)
        }
        let selectedStatus = application.staticTexts["selected-day-classification"]

        guard let expectedStatus else {
            XCTAssertFalse(selectedStatus.exists, file: file, line: line)
            return
        }

        XCTAssertTrue(selectedStatus.exists, file: file, line: line)
        XCTAssertEqual(
            selectedStatus.value as? String,
            expectedStatus,
            file: file,
            line: line
        )
    }

    @MainActor
    private func todayCellIdentifier() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 7 * 60 * 60) ?? .gmt
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return "day-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
