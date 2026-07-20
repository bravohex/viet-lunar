import AppKit
import Foundation

/// Bridges system notifications into a typed, thread-safe AsyncStream.
/// Observer tokens are created once during initialization and only touched
/// again during deinitialization, so unchecked sendability is constrained.
public final class SystemLifecycleSource: LifecycleEventSourcing, @unchecked Sendable {
    private let stream: AsyncStream<AppLifecycleEvent>
    private let continuation: AsyncStream<AppLifecycleEvent>.Continuation
    private var observers: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    public init(
        notificationCenter: NotificationCenter = .default,
        workspaceNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter
    ) {
        let pair = AsyncStream<AppLifecycleEvent>.makeStream(
            bufferingPolicy: .bufferingNewest(32)
        )
        stream = pair.stream
        continuation = pair.continuation

        observe(
            center: notificationCenter,
            name: .NSCalendarDayChanged,
            event: .calendarDayChanged
        )
        observe(
            center: notificationCenter,
            name: .NSSystemClockDidChange,
            event: .systemClockChanged
        )
        observe(
            center: notificationCenter,
            name: .NSSystemTimeZoneDidChange,
            event: .systemTimeZoneChanged
        )
        observe(
            center: notificationCenter,
            name: NSApplication.didBecomeActiveNotification,
            event: .applicationBecameActive
        )
        observe(
            center: workspaceNotificationCenter,
            name: NSWorkspace.didWakeNotification,
            event: .systemWoke
        )
    }

    deinit {
        for observer in observers {
            observer.center.removeObserver(observer.token)
        }
        continuation.finish()
    }

    public func events() -> AsyncStream<AppLifecycleEvent> {
        stream
    }

    public func emit(_ event: AppLifecycleEvent) {
        continuation.yield(event)
    }

    private func observe(
        center: NotificationCenter,
        name: Notification.Name,
        event: AppLifecycleEvent
    ) {
        let token = center.addObserver(
            forName: name,
            object: nil,
            queue: nil
        ) { [continuation] _ in
            continuation.yield(event)
        }
        observers.append((center, token))
    }
}
