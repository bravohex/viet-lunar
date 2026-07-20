import AppKit
import Foundation
import SwiftUI
import VietLunarCore
import VietLunarInfrastructure

@main
struct VietLunarApp: App {
    @StateObject private var appState: AppState

    init() {
        let store: UserDefaultsPreferencesStore
#if DEBUG
        if let suiteName = ProcessInfo.processInfo.environment["VIETLUNAR_TEST_PREFERENCES_SUITE"],
           let defaults = UserDefaults(suiteName: suiteName) {
            defaults.removePersistentDomain(forName: suiteName)
            store = UserDefaultsPreferencesStore(userDefaults: defaults)
        } else {
            store = UserDefaultsPreferencesStore()
        }
#else
        store = UserDefaultsPreferencesStore()
#endif
        _appState = StateObject(
            wrappedValue: AppState(preferencesStore: store)
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuPopoverView()
                .environmentObject(appState)
                .onAppear {
                    appState.popoverOpened()
                }
        } label: {
            MenuBarLabelView(
                presentation: appState.menuBarPresentation,
                showsIcon: appState.preferences.titleFormat.isIconOnly
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

private struct MenuBarLabelView: View {
    let presentation: MenuBarTitlePresentation
    let showsIcon: Bool

    var body: some View {
        if showsIcon {
            HStack(spacing: 4) {
                Image(systemName: "moon.circle.fill")
                if let title = presentation.title {
                    Text(title)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(presentation.accessibilityLabel)
        } else if let title = presentation.title {
            Text(title)
                .accessibilityLabel(presentation.accessibilityLabel)
        } else {
            Text("ÂL")
                .accessibilityLabel(presentation.accessibilityLabel)
        }
    }
}
