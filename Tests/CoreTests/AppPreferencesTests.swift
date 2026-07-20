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
                granularities: [.vietnamMidnight],
                displayedClockTimeZone: timeZone
            )
        )

        var preferences = AppPreferences.defaultValue
        preferences.showsClock = true
        XCTAssertEqual(
            preferences.refreshRequirements(displayedClockTimeZone: timeZone),
            RefreshRequirements(
                granularities: [.vietnamMidnight, .minute],
                displayedClockTimeZone: timeZone
            )
        )
    }
}
