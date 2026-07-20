import SwiftUI
import VietLunarCore

struct MonthGridView: View {
    @EnvironmentObject private var appState: AppState

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 36), spacing: 3),
        count: 7
    )
    private let weekdayLabels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Button {
                    appState.navigateMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .disabled(!appState.canNavigateToPreviousMonth)
                .accessibilityLabel("Tháng trước")
                .accessibilityIdentifier("previous-month-button")

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
                .disabled(!appState.canNavigateToNextMonth)
                .accessibilityLabel("Tháng sau")
                .accessibilityIdentifier("next-month-button")
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
                    }
                }
            }
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
        .accessibilityIdentifier("day-\(cell.solarDate.year)-\(cell.solarDate.month)-\(cell.solarDate.day)")
    }
}
