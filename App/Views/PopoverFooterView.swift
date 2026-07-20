import AppKit
import SwiftUI

struct PopoverFooterView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Button {
                appState.returnToToday()
            } label: {
                Label {
                    Text(
                        AppLocalization.text(
                            "footer.today",
                            fallback: "Hôm nay"
                        )
                    )
                } icon: {
                    AssetIconView(.today, size: 16)
                }
            }
            .accessibilityIdentifier("today-button")
            .help(
                AppLocalization.text(
                    "footer.today.help",
                    fallback: "Trở về ngày hôm nay"
                )
            )

            Button {
                VietLunarApplicationDelegate.shared.showSettings()
            } label: {
                Label {
                    Text(
                        AppLocalization.text(
                            "footer.settings",
                            fallback: "Cài đặt"
                        )
                    )
                } icon: {
                    AssetIconView(.settings, size: 16)
                }
            }
            .accessibilityIdentifier("settings-button")
            .help(
                AppLocalization.text(
                    "footer.settings.help",
                    fallback: "Mở cài đặt VietLunar"
                )
            )

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label {
                    Text(
                        AppLocalization.text(
                            "footer.quit",
                            fallback: "Thoát VietLunar"
                        )
                    )
                } icon: {
                    AssetIconView(.quit, size: 16)
                }
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
