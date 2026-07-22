import SwiftUI
import VietLunarCore

struct MonthGridView: View {
    @EnvironmentObject private var appState: AppState
    @FocusState private var isGridFocused: Bool

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 36), spacing: 3),
        count: 7
    )
    private var weekdayHeaders: [WeekdayHeader] {
        switch appState.preferences.weekStart {
        case .monday:
            localizedWeekdayHeaders(startingOnMonday: true)
        case .sunday:
            localizedWeekdayHeaders(startingOnMonday: false)
        }
    }

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Button {
                    appState.navigateMonth(by: -1)
                } label: {
                    AssetIconView(.previous, size: 16)
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
                    AssetIconView(.next, size: 16)
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
                ForEach(weekdayHeaders) { header in
                    Text(header.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(header.color)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(header.label)
                        .accessibilityValue(header.label)
                        .accessibilityIdentifier(
                            "weekday-header-\(header.id)"
                        )
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
            .hidesFocusEffectWhenSupported()
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

    private func localizedWeekdayHeaders(
        startingOnMonday: Bool
    ) -> [WeekdayHeader] {
        let mondayFirst = [
            WeekdayHeader(
                id: 2,
                label: AppLocalization.text(
                    "weekday.short.monday",
                    fallback: "T2"
                ),
                color: .secondary
            ),
            WeekdayHeader(
                id: 3,
                label: AppLocalization.text(
                    "weekday.short.tuesday",
                    fallback: "T3"
                ),
                color: .secondary
            ),
            WeekdayHeader(
                id: 4,
                label: AppLocalization.text(
                    "weekday.short.wednesday",
                    fallback: "T4"
                ),
                color: .secondary
            ),
            WeekdayHeader(
                id: 5,
                label: AppLocalization.text(
                    "weekday.short.thursday",
                    fallback: "T5"
                ),
                color: .secondary
            ),
            WeekdayHeader(
                id: 6,
                label: AppLocalization.text(
                    "weekday.short.friday",
                    fallback: "T6"
                ),
                color: .secondary
            ),
            WeekdayHeader(
                id: 7,
                label: AppLocalization.text(
                    "weekday.short.saturday",
                    fallback: "T7"
                ),
                color: .blue
            ),
            WeekdayHeader(
                id: 1,
                label: AppLocalization.text(
                    "weekday.short.sunday",
                    fallback: "CN"
                ),
                color: .red
            )
        ]
        guard !startingOnMonday else {
            return mondayFirst
        }
        return [mondayFirst[6]] + mondayFirst[0...5]
    }
}

private struct WeekdayHeader: Identifiable {
    let id: Int
    let label: String
    let color: Color
}

private extension View {
    @ViewBuilder
    func hidesFocusEffectWhenSupported() -> some View {
        if #available(macOS 14.0, *) {
            focusEffectDisabled()
        } else {
            self
        }
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

                dayClassificationIndicator
            }
            .frame(maxWidth: .infinity, minHeight: 39)
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
        .help("\(accessibilityLabel), \(dayClassificationText)")
    }

    private var accessibilityLabel: String {
        VietnameseCalendarFormatter.cellAccessibilityLabel(
            for: cell,
            yearCanChi: CanChiCalculator().year(forLunarYear: cell.lunarDate.year)
        )
    }

    private var accessibilityValue: String {
        let selectionStatus: String = switch (isSelected, cell.isToday) {
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

        return [selectionStatus, dayClassificationText]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var dayClassification: TraditionalDayClassification {
        TraditionalDayClassifier.classification(
            for: cell.lunarDate,
            solarDate: cell.solarDate
        )
    }

    private var dayClassificationText: String {
        switch dayClassification {
        case .auspicious:
            AppLocalization.text(
                "day_classification.auspicious",
                fallback: "Ngày hoàng đạo"
            )
        case .inauspicious:
            AppLocalization.text(
                "day_classification.inauspicious",
                fallback: "Ngày hắc đạo"
            )
        case .ordinary:
            AppLocalization.text(
                "day_classification.ordinary",
                fallback: "Ngày thường"
            )
        }
    }

    @ViewBuilder
    private var dayClassificationIndicator: some View {
        Group {
            switch dayClassification {
            case .auspicious:
                Circle().fill(Color.green)
            case .inauspicious:
                Circle().fill(Color.gray)
            case .ordinary:
                Color.clear
            }
        }
        .frame(width: 5, height: 5)
        .accessibilityHidden(true)
    }
}
