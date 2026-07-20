import AppKit
import SwiftUI

struct PopoverFooterView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Button(AppLocalization.text("footer.today", fallback: "Hôm nay")) {
                appState.returnToToday()
            }
            .accessibilityIdentifier("today-button")
            .help(
                AppLocalization.text(
                    "footer.today.help",
                    fallback: "Trở về ngày hôm nay"
                )
            )

            Button(
                AppLocalization.text("footer.settings", fallback: "Cài đặt")
            ) {
                VietLunarApplicationDelegate.shared.showSettings()
            }
            .accessibilityIdentifier("settings-button")
            .help(
                AppLocalization.text(
                    "footer.settings.help",
                    fallback: "Mở cài đặt VietLunar"
                )
            )

            Spacer()

            Button(
                AppLocalization.text("footer.quit", fallback: "Thoát VietLunar")
            ) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .accessibilityIdentifier("quit-button")
            .help(
                AppLocalization.text(
                    "footer.quit.help",
                    fallback: "Thoát hoàn toàn khỏi VietLunar (⌘Q)"
                )
            )
        }
        .controlSize(.small)
    }
}
