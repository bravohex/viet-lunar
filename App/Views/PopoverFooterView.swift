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

            settingsControl

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

    @ViewBuilder
    private var settingsControl: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text(AppLocalization.text("footer.settings", fallback: "Cài đặt"))
            }
            .accessibilityIdentifier("settings-button")
            .help(
                AppLocalization.text(
                    "footer.settings.help",
                    fallback: "Mở cài đặt VietLunar"
                )
            )
        } else {
            Button(
                AppLocalization.text("footer.settings", fallback: "Cài đặt")
            ) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.sendAction(
                    Selector(("showPreferencesWindow:")),
                    to: nil,
                    from: nil
                )
            }
            .accessibilityIdentifier("settings-button")
            .help(
                AppLocalization.text(
                    "footer.settings.help",
                    fallback: "Mở cài đặt VietLunar"
                )
            )
        }
    }
}
