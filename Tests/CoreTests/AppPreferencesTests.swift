import Foundation
import XCTest
@testable import VietLunarCore

final class AppPreferencesTests: XCTestCase {
    func testTextTitleFlagsMapToAllSupportedCombinations() {
        XCTAssertEqual(
            MenuBarTitleFormat.lunarDate.withSolarDate(true),
            .solarAndLunar
        )
        XCTAssertEqual(
            MenuBarTitleFormat.lunarDate.withDayCanChi(true),
            .lunarAndDayCanChi
        )
        XCTAssertEqual(
            MenuBarTitleFormat.solarAndLunar.withDayCanChi(true),
            .solarLunarAndDayCanChi
        )
        XCTAssertEqual(
            MenuBarTitleFormat.solarLunarAndDayCanChi.withSolarDate(false),
            .lunarAndDayCanChi
        )
        XCTAssertEqual(
            MenuBarTitleFormat.iconOnly.withSolarDate(true),
            .iconOnly
        )
    }

    func testClockPreferenceAddsMinuteBoundaryWithoutDroppingMidnight() throws {
        let timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        XCTAssertEqual(
            AppPreferences.defaultValue.refreshRequirements(
                displayedClockTimeZone: timeZone
            ),
            RefreshRequirements(
                granularities: [.vietnamMidnight, .canChiHour],
                displayedClockTimeZone: timeZone
            )
        )

        var preferences = AppPreferences.defaultValue
        preferences.showsClock = true
        XCTAssertEqual(
            preferences.refreshRequirements(displayedClockTimeZone: timeZone),
            RefreshRequirements(
                granularities: [.vietnamMidnight, .canChiHour, .minute],
                displayedClockTimeZone: timeZone
            )
        )
    }

    func testHiddenClockStillRefreshesAtCanChiHourBoundaries() throws {
        let parser = ISO8601DateFormatter()
        let requirements = AppPreferences.defaultValue.refreshRequirements(
            displayedClockTimeZone: VietnamCalendarTime.timeZone
        )
        for (before, expected) in [
            ("2026-10-25T17:59:00Z", "2026-10-25T18:00:00Z"),
            ("2026-10-26T15:59:00Z", "2026-10-26T16:00:00Z"),
            ("2026-10-26T16:59:00Z", "2026-10-26T17:00:00Z")
        ] {
            let boundary = try BoundaryCalculator().nextBoundary(
                after: XCTUnwrap(parser.date(from: before)), requirements: requirements
            )
            XCTAssertEqual(boundary, parser.date(from: expected))
        }
    }
}
