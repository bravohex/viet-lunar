public enum AppLifecycleEvent: Equatable, Sendable {
    case calendarDayChanged
    case systemClockChanged
    case systemTimeZoneChanged
    case applicationBecameActive
    case systemWoke
    case popoverOpened
    case scheduledBoundary
}

public protocol LifecycleEventSourcing: Sendable {
    func events() -> AsyncStream<AppLifecycleEvent>
    func emit(_ event: AppLifecycleEvent)
}
