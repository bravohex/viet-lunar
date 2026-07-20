public struct MenuBarTitlePresentation: Equatable, Sendable {
    /// Nil selects the moon icon-only menu-bar label.
    public let title: String?
    public let accessibilityLabel: String

    public init(title: String?, accessibilityLabel: String) {
        self.title = title
        self.accessibilityLabel = accessibilityLabel
    }
}
