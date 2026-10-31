import SwiftUI

struct MenuPopoverView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CalendarHeaderView()

            if let errorMessage = appState.errorMessage {
                ErrorMessageLabel(errorMessage, identifier: "error-banner")
            }

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
        .onExitCommand {
            VietLunarApplicationDelegate.shared.closePopover()
        }
    }
}

/// Error text with a warning symbol so the state is not conveyed by red alone.
struct ErrorMessageLabel: View {
    private let message: String
    private let identifier: String

    init(_ message: String, identifier: String) {
        self.message = message
        self.identifier = identifier
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(identifier)
        }
        .font(.caption)
        .foregroundStyle(.red)
    }
}
