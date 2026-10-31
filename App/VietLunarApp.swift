import AppKit
import Foundation
import SwiftUI
import VietLunarInfrastructure

@main
@MainActor
final class VietLunarApplicationDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static let shared = VietLunarApplicationDelegate()

    private var appState: AppState?
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindowController: NSWindowController?

    static func main() {
        let application = NSApplication.shared
        application.delegate = shared
        application.setActivationPolicy(.accessory)
        if let argument = CommandLine.arguments.dropFirst().first,
           let command = LoginItemCommand(rawValue: argument) {
            let result = command.execute(using: SMLoginItemService())
            print("App: \(Bundle.main.bundlePath)")
            print(result.message)
            exit(result.exitCode)
        }
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let launchInterval = AppPerformance.signposter.beginInterval(
            "Application App Work"
        )
        defer {
            AppPerformance.signposter.endInterval(
                "Application App Work",
                launchInterval
            )
        }

        let state = AppState(preferencesStore: makePreferencesStore())
        state.menuBarPresentationDidChange = { [weak self] in
            self?.updateStatusItem()
        }
        appState = state

        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        item.autosaveName = "VietLunarStatusItem"
        if let button = item.button {
            button.identifier = NSUserInterfaceItemIdentifier(
                "vietlunar-status-item"
            )
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp])
        }
        statusItem = item
        updateStatusItem()
        item.button?.window?.displayIfNeeded()
        AppPerformance.signposter.emitEvent("Status Item Ready")
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState?.menuBarPresentationDidChange = nil
        popover?.close()
        settingsWindowController?.close()
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }

    func showSettings() {
        guard let appState else {
            return
        }

        closePopover()
        appState.settingsAppeared()
        let windowController: NSWindowController
        if let settingsWindowController {
            windowController = settingsWindowController
        } else {
            let rootView = SettingsView().environmentObject(appState)
            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = AppLocalization.text(
                "footer.settings",
                fallback: "Cài đặt"
            )
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 540, height: 560))
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            windowController = NSWindowController(window: window)
            settingsWindowController = windowController
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
    }

    func closePopover() {
        popover?.performClose(nil)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindowController?.window {
            appState?.settingsAppeared()
        }
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindowController?.window {
            appState?.settingsDisappeared()
        }
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover?.isShown == true {
            closePopover()
            return
        }
        showPopover(relativeTo: sender)
    }

    private func showPopover(relativeTo button: NSStatusBarButton) {
        guard let appState else {
            return
        }
        let intervalName: StaticString = popover == nil
            ? "Popover First Open"
            : "Popover Subsequent Open"
        let interval = AppPerformance.signposter.beginInterval(intervalName)
        defer {
            AppPerformance.signposter.endInterval(intervalName, interval)
        }
        appState.popoverOpened()

        let activePopover: NSPopover
        if let popover {
            activePopover = popover
        } else {
            let createdPopover = NSPopover()
            createdPopover.behavior = .transient
            createdPopover.animates = false
            createdPopover.contentViewController = NSHostingController(
                rootView: MenuPopoverView().environmentObject(appState)
            )
            popover = createdPopover
            activePopover = createdPopover
        }

        activePopover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .maxY
        )
        keepPopoverOnScreen(activePopover, relativeTo: button)
        activePopover.contentViewController?.view.window?.displayIfNeeded()
    }

    private func keepPopoverOnScreen(
        _ popover: NSPopover,
        relativeTo button: NSStatusBarButton
    ) {
        guard let window = popover.contentViewController?.view.window,
              let screen = button.window?.screen
        else {
            return
        }

        let visibleFrame = screen.visibleFrame
        var frame = window.frame
        frame.origin.x = min(
            max(frame.origin.x, visibleFrame.minX),
            visibleFrame.maxX - frame.width
        )
        frame.origin.y = min(
            max(frame.origin.y, visibleFrame.minY),
            visibleFrame.maxY - frame.height
        )
        window.setFrame(frame, display: true)
    }

    private func updateStatusItem() {
        guard let appState, let button = statusItem?.button else {
            return
        }

        let presentation = appState.menuBarPresentation
        let image: NSImage?
        if appState.preferences.titleFormat.isIconOnly {
            image = IconAsset.menuBarLunar.nsImage
                ?? NSImage(
                    systemSymbolName: "moon.circle.fill",
                    accessibilityDescription: presentation.accessibilityLabel
                )
            image?.isTemplate = true
        } else {
            image = nil
        }
        StatusItemRenderer.apply(presentation, icon: image, to: button)
    }

    private func makePreferencesStore() -> UserDefaultsPreferencesStore {
#if DEBUG
        if let suiteName = ProcessInfo.processInfo.environment[
            "VIETLUNAR_TEST_PREFERENCES_SUITE"
        ], let defaults = UserDefaults(suiteName: suiteName) {
            return UserDefaultsPreferencesStore(userDefaults: defaults)
        }
#endif
        return UserDefaultsPreferencesStore()
    }
}
