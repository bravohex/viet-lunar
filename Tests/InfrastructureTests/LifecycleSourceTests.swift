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
        await drainTasks()
        XCTAssertEqual(recorder.count, 1)

        source.emit(.systemWoke)
        await drainTasks()
        XCTAssertEqual(recorder.count, 2)

        coordinator.stop()
        source.emit(.popoverOpened)
        await drainTasks()
        XCTAssertEqual(recorder.count, 2)
    }

    @MainActor
    private func drainTasks() async {
        for _ in 0..<10 {
            await Task.yield()
        }
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
}
