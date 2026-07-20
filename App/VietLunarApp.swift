import AppKit
import Foundation
import SwiftUI
import VietLunarInfrastructure

@main
@MainActor
final class VietLunarApplicationDelegate: NSObject, NSApplicationDelegate {
    static let shared = VietLunarApplicationDelegate()

    private var appState: AppState?
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindowController: NSWindowController?

    static func main() {
        let application = NSApplication.shared
        application.delegate = shared
        application.setActivationPolicy(.accessory)
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
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
            window.setContentSize(NSSize(width: 540, height: 440))
            window.isReleasedWhenClosed = false
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
        if appState.preferences.titleFormat.isIconOnly {
            let image = NSImage(
                systemSymbolName: "moon.circle.fill",
                accessibilityDescription: presentation.accessibilityLabel
            )
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.title = ""
        } else {
            button.image = nil
            button.imagePosition = .noImage
            button.title = presentation.title
                ?? AppLocalization.text(
                    "common.lunar_abbreviation",
                    fallback: "ÂL"
                )
        }
        button.toolTip = presentation.accessibilityLabel
        button.setAccessibilityLabel(presentation.accessibilityLabel)
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
