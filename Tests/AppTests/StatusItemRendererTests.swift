import AppKit
import VietLunarCore
import XCTest

final class StatusItemRendererTests: XCTestCase {
    @MainActor
    func testIconAndClockPreserveBothImageAndText() {
        let button = NSButton()
        let icon = NSImage(size: NSSize(width: 16, height: 16))
        StatusItemRenderer.apply(
            MenuBarTitlePresentation(title: "14:32", accessibilityLabel: "Giờ 14:32"),
            icon: icon, to: button
        )
        XCTAssertEqual(button.title, "14:32")
        XCTAssertEqual(button.imagePosition, .imageLeft)
        XCTAssertTrue(button.image === icon)
        XCTAssertEqual(button.toolTip, "Giờ 14:32")
    }

    @MainActor
    func testIconWithoutClockAndTextOnlyTransitions() {
        let button = NSButton()
        StatusItemRenderer.apply(
            MenuBarTitlePresentation(title: nil, accessibilityLabel: "Lịch âm"),
            icon: NSImage(size: NSSize(width: 16, height: 16)), to: button
        )
        XCTAssertEqual(button.title, "")
        XCTAssertEqual(button.imagePosition, .imageOnly)
        StatusItemRenderer.apply(
            MenuBarTitlePresentation(title: "17/09 ÂL", accessibilityLabel: "Lịch âm"),
            icon: nil, to: button
        )
        // NSButton may retain an internal placeholder image; noImage controls visibility.
        XCTAssertEqual(button.title, "17/09 ÂL")
        XCTAssertEqual(button.imagePosition, .noImage)
    }
}
