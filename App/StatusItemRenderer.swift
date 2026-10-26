import AppKit
import VietLunarCore

enum StatusItemRenderer {
    @MainActor
    static func apply(
        _ presentation: MenuBarTitlePresentation,
        icon: NSImage?,
        to button: NSButton
    ) {
        button.image = icon
        button.title = presentation.title ?? (icon == nil
            ? AppLocalization.text("common.lunar_abbreviation", fallback: "ÂL")
            : "")
        // Set position after title: AppKit can change it when assigning an empty title.
        button.imagePosition = icon == nil ? .noImage
            : (button.title.isEmpty ? .imageOnly : .imageLeft)
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = presentation.accessibilityLabel
        button.setAccessibilityLabel(presentation.accessibilityLabel)
    }
}
