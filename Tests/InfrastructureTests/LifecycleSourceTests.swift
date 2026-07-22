import AppKit
import Foundation
import XCTest
@testable import VietLunarInfrastructure

final class LifecycleSourceTests: XCTestCase {
    @MainActor
    func testSystemNotificationsMapToTypedEvents() async {
        let center = NotificationCenter()
        let workspaceCenter = NotificationCenter()
        let source = SystemLifecycleSource(
            notificationCenter: center,
            workspaceNotificationCenter: workspaceCenter
        )
        var iterator = source.events().makeAsyncIterator()

        center.post(name: .NSCalendarDayChanged, object: nil)
        let dayChanged = await iterator.next()
        XCTAssertEqual(dayChanged, .calendarDayChanged)

        center.post(name: .NSSystemClockDidChange, object: nil)
        let clockChanged = await iterator.next()
        XCTAssertEqual(clockChanged, .systemClockChanged)

        center.post(name: .NSSystemTimeZoneDidChange, object: nil)
        let timeZoneChanged = await iterator.next()
        XCTAssertEqual(timeZoneChanged, .systemTimeZoneChanged)

        center.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        let becameActive = await iterator.next()
        XCTAssertEqual(becameActive, .applicationBecameActive)

        workspaceCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
        let woke = await iterator.next()
        XCTAssertEqual(woke, .systemWoke)
    }

    @MainActor
    func testExplicitEventsSupportPopoverAndScheduledBoundary() async {
        let source = ManualLifecycleSource()
        var iterator = source.events().makeAsyncIterator()

        source.emit(.popoverOpened)
        let popoverOpened = await iterator.next()
        XCTAssertEqual(popoverOpened, .popoverOpened)

        source.emit(.scheduledBoundary)
        let scheduledBoundary = await iterator.next()
        XCTAssertEqual(scheduledBoundary, .scheduledBoundary)
    }

    @MainActor
    func testCoordinatorCoalescesBurstAndStopsCleanly() async {
        let source = ManualLifecycleSource()
        let recorder = RefreshRecorder()
        let coordinator = LifecycleEventCoordinator(source: source) {
            recorder.recordRefresh()
        }
        coordinator.start()
        coordinator.start() // Idempotent: never create a second stream consumer.

        source.emit(.calendarDayChanged)
        source.emit(.systemClockChanged)
        source.emit(.systemTimeZoneChanged)
        let didProcessInitialBurst = await recorder.waitUntilCount(1)
        XCTAssertTrue(
            didProcessInitialBurst,
            "Coordinator did not process the initial lifecycle event burst."
        )
        XCTAssertEqual(recorder.count, 1)

        source.emit(.systemWoke)
        let didProcessWakeEvent = await recorder.waitUntilCount(2)
        XCTAssertTrue(
            didProcessWakeEvent,
            "Coordinator did not process the subsequent lifecycle event."
        )
        XCTAssertEqual(recorder.count, 2)

        coordinator.stop()
        source.emit(.popoverOpened)
        XCTAssertEqual(recorder.count, 2)
    }
}

private final class ManualLifecycleSource: LifecycleEventSourcing, @unchecked Sendable {
    private let stream: AsyncStream<AppLifecycleEvent>
    private let continuation: AsyncStream<AppLifecycleEvent>.Continuation

    init() {
        let pair = AsyncStream<AppLifecycleEvent>.makeStream(
            bufferingPolicy: .bufferingNewest(32)
        )
        stream = pair.stream
        continuation = pair.continuation
    }

    func events() -> AsyncStream<AppLifecycleEvent> {
        stream
    }

    func emit(_ event: AppLifecycleEvent) {
        continuation.yield(event)
    }
}

@MainActor
private final class RefreshRecorder {
    private(set) var count = 0

    func recordRefresh() {
        count += 1
    }

    func waitUntilCount(_ expectedCount: Int, timeout: Duration = .seconds(1)) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while count < expectedCount {
            guard clock.now < deadline else {
                return false
            }
            try? await Task<Never, Never>.sleep(for: .milliseconds(5))
        }

        return count == expectedCount
    }
}
