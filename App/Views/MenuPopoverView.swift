import SwiftUI

struct MenuPopoverView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let snapshot = appState.currentSnapshot {
                CalendarHeaderView(snapshot: snapshot)
            }

            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("error-banner")
            }

            Divider()

            MonthGridView()

            if let selectedCell = appState.selectedCell,
               let snapshot = appState.currentSnapshot {
                Divider()
                SelectedDayDetailView(
                    cell: selectedCell,
                    currentSnapshot: snapshot
                )
            }

            Divider()
            PopoverFooterView()
        }
        .padding(14)
        .frame(width: 380)
        .background(.regularMaterial)
        .accessibilityIdentifier("menu-popover")
    }
}
