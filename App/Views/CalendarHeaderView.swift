import SwiftUI
import VietLunarCore

/// Month title with previous/next controls.
///
/// The selected-day panel below the grid is the only place that describes a
/// day, so the popover has no separate "today" block repeating it.
struct CalendarHeaderView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            monthButton(
                icon: .previous,
                offset: -1,
                key: .leftArrow,
                isEnabled: appState.canNavigateToPreviousMonth,
                label: AppLocalization.text(
                    "navigation.previous_month",
                    fallback: "Tháng trước"
                ),
                help: AppLocalization.text(
                    "navigation.previous_month.help",
                    fallback: "Xem tháng trước (⌘←)"
                ),
                identifier: "previous-month-button"
            )

            Spacer()

            if let visibleMonth = appState.visibleMonth {
                Text(VietnameseCalendarFormatter.monthTitle(visibleMonth))
                    .font(.headline)
                    .accessibilityIdentifier("visible-month-title")
            }

            Spacer()

            monthButton(
                icon: .next,
                offset: 1,
                key: .rightArrow,
                isEnabled: appState.canNavigateToNextMonth,
                label: AppLocalization.text(
                    "navigation.next_month",
                    fallback: "Tháng sau"
                ),
                help: AppLocalization.text(
                    "navigation.next_month.help",
                    fallback: "Xem tháng sau (⌘→)"
                ),
                identifier: "next-month-button"
            )
        }
    }

    private func monthButton(
        icon: IconAsset,
        offset: Int,
        key: KeyEquivalent,
        isEnabled: Bool,
        label: String,
        help: String,
        identifier: String
    ) -> some View {
        Button {
            appState.navigateMonth(by: offset)
        } label: {
            AssetIconView(icon, size: 16)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(key, modifiers: .command)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
        .help(help)
    }
}
