import AppKit
import SwiftUI
import VietLunarCore

@main
struct VietLunarApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuPopoverPlaceholderView()
                .environmentObject(appState)
                .onAppear {
                    appState.refresh()
                }
        } label: {
            if let title = appState.menuBarPresentation.title {
                Text(title)
                    .accessibilityLabel(appState.menuBarPresentation.accessibilityLabel)
            } else {
                Image(systemName: "moon.circle.fill")
                    .accessibilityLabel(appState.menuBarPresentation.accessibilityLabel)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsPlaceholderView()
        }
    }
}

private struct MenuPopoverPlaceholderView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("VietLunar")
                    .font(.headline)
                Text("Lịch âm Việt Nam trên thanh menu")
                    .foregroundStyle(.secondary)
            }

            Divider()

            if let snapshot = appState.currentSnapshot {
                Text(VietnameseCalendarFormatter.fullGregorianDate(snapshot.solarDate))
                    .accessibilityIdentifier("today-header")
                Text(
                    VietnameseCalendarFormatter.fullLunarDate(
                        snapshot.lunarDate,
                        yearCanChi: snapshot.yearCanChi
                    )
                )
                .foregroundStyle(.secondary)
            } else if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Divider()

            HStack {
                settingsControl
                Spacer()
                Button("Thoát VietLunar") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
                .accessibilityIdentifier("quit-button")
            }

            Text(versionText)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(width: 300)
        .accessibilityIdentifier("menu-popover")
    }

    @ViewBuilder
    private var settingsControl: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text("Cài đặt")
            }
            .accessibilityIdentifier("settings-button")
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
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "Phiên bản \(version ?? "0.1.0")"
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cài đặt VietLunar")
                .font(.title2.bold())
            Text("Các tùy chọn hiển thị sẽ được bổ sung ở milestone M7.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 420, height: 180, alignment: .topLeading)
        .accessibilityIdentifier("settings-placeholder")
    }
}
