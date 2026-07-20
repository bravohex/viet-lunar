import AppKit
import SwiftUI
import VietLunarCore

@main
struct VietLunarApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuPopoverView()
                .environmentObject(appState)
                .onAppear {
                    appState.popoverOpened()
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

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cài đặt VietLunar")
                .font(.title2.bold())
                .accessibilityIdentifier("settings-title")
            Text("Các tùy chọn hiển thị sẽ được bổ sung ở milestone M7.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 420, height: 180, alignment: .topLeading)
    }
}
