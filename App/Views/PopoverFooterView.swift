import AppKit
import SwiftUI

struct PopoverFooterView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Button("Hôm nay") {
                appState.returnToToday()
            }
            .accessibilityIdentifier("today-button")
            .help("Trở về ngày hôm nay")

            settingsControl

            Spacer()

            Button("Thoát VietLunar") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .accessibilityIdentifier("quit-button")
            .help("Thoát hoàn toàn khỏi VietLunar (⌘Q)")
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var settingsControl: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text("Cài đặt")
            }
            .accessibilityIdentifier("settings-button")
            .help("Mở cài đặt VietLunar")
        } else {
            Button("Cài đặt") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.sendAction(
                    Selector(("showPreferencesWindow:")),
                    to: nil,
                    from: nil
                )
            }
            .accessibilityIdentifier("settings-button")
            .help("Mở cài đặt VietLunar")
        }
    }
}
