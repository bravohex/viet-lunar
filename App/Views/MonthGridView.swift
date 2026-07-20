import SwiftUI
import VietLunarCore

struct MonthGridView: View {
    @EnvironmentObject private var appState: AppState
    @FocusState private var isGridFocused: Bool

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 36), spacing: 3),
        count: 7
    )
    private var weekdayLabels: [String] {
        switch appState.preferences.weekStart {
        case .monday:
            localizedWeekdays(startingOnMonday: true)
        case .sunday:
            localizedWeekdays(startingOnMonday: false)
        }
    }

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Button {
                    appState.navigateMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.leftArrow, modifiers: .command)
                .disabled(!appState.canNavigateToPreviousMonth)
                .accessibilityLabel(
                    AppLocalization.text(
                        "navigation.previous_month",
                        fallback: "Tháng trước"
                    )
                )
                .accessibilityIdentifier("previous-month-button")
                .help(
                    AppLocalization.text(
                        "navigation.previous_month.help",
                        fallback: "Xem tháng trước (⌘←)"
                    )
                )

                Spacer()

                if let visibleMonth = appState.visibleMonth {
                    Text(VietnameseCalendarFormatter.monthTitle(visibleMonth))
                        .font(.headline)
                        .accessibilityIdentifier("visible-month-title")
                }

                Spacer()

                Button {
                    appState.navigateMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.rightArrow, modifiers: .command)
                .disabled(!appState.canNavigateToNextMonth)
                .accessibilityLabel(
                    AppLocalization.text(
                        "navigation.next_month",
                        fallback: "Tháng sau"
                    )
                )
                .accessibilityIdentifier("next-month-button")
                .help(
                    AppLocalization.text(
                        "navigation.next_month.help",
                        fallback: "Xem tháng sau (⌘→)"
                    )
                )
            }

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(appState.monthCells) { cell in
                    MonthGridCellView(
                        cell: cell,
                        isSelected: cell.solarDate == appState.selectedSolarDate
                    ) {
                        appState.select(cell.solarDate)
                        isGridFocused = true
                    }
                }
            }
            .focusable()
            .focused($isGridFocused)
            .onMoveCommand { direction in
                switch direction {
                case .left:
                    appState.moveSelection(byDays: -1)
                case .right:
                    appState.moveSelection(byDays: 1)
                case .up:
                    appState.moveSelection(byDays: -7)
                case .down:
                    appState.moveSelection(byDays: 7)
                default:
                    break
                }
            }
            .onAppear {
                isGridFocused = true
            }
        }
    }

    private func localizedWeekdays(startingOnMonday: Bool) -> [String] {
        let mondayFirst = [
            AppLocalization.text("weekday.short.monday", fallback: "T2"),
            AppLocalization.text("weekday.short.tuesday", fallback: "T3"),
            AppLocalization.text("weekday.short.wednesday", fallback: "T4"),
            AppLocalization.text("weekday.short.thursday", fallback: "T5"),
            AppLocalization.text("weekday.short.friday", fallback: "T6"),
            AppLocalization.text("weekday.short.saturday", fallback: "T7"),
            AppLocalization.text("weekday.short.sunday", fallback: "CN")
        ]
        guard !startingOnMonday else {
            return mondayFirst
        }
        return [mondayFirst[6]] + mondayFirst[0...5]
    }
}

private struct MonthGridCellView: View {
    let cell: MonthGridCell
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(String(cell.solarDate.day))
                    .font(.body.weight(isSelected ? .semibold : .regular))
                Text(VietnameseCalendarFormatter.monthGridLunarLabel(cell.lunarDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 34)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.28) : .clear)
            }
            .overlay {
                if cell.isToday {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor, lineWidth: 1.5)
                }
            }
            .opacity(cell.isInDisplayedMonth ? 1 : 0.42)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("day-\(cell.solarDate.year)-\(cell.solarDate.month)-\(cell.solarDate.day)")
        .help(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        VietnameseCalendarFormatter.cellAccessibilityLabel(
            for: cell,
            yearCanChi: CanChiCalculator().year(forLunarYear: cell.lunarDate.year)
        )
    }

    private var accessibilityValue: String {
        switch (isSelected, cell.isToday) {
        case (true, true):
            AppLocalization.text(
                "selection.selected_today",
                fallback: "Đã chọn, hôm nay"
            )
        case (true, false):
            AppLocalization.text("selection.selected", fallback: "Đã chọn")
        case (false, true):
            AppLocalization.text("selection.today", fallback: "Hôm nay")
        case (false, false): ""
        }
    }
}
