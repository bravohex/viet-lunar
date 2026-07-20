import Foundation
import XCTest
import VietLunarCore
@testable import VietLunarInfrastructure

final class OneShotBoundarySchedulerTests: XCTestCase {
    @MainActor
    func testSchedulePassesDelayAndToleranceToSleeper() async throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let sleeper = ManualBoundarySleeper()
        let scheduler = OneShotBoundaryScheduler(
            clock: FixedClock(instant: now),
            sleeper: sleeper
        )

        scheduler.schedule(at: now.addingTimeInterval(120), tolerance: 2.5) {}

        let request = try await sleeper.waitForRequest(at: 0)
        XCTAssertEqual(request.duration, 120)
        XCTAssertEqual(request.tolerance, 2.5)
        XCTAssertTrue(scheduler.hasScheduledBoundary)
        scheduler.cancel()
    }

    @MainActor
    func testReplacementCancelsOldTaskAndOnlyNewestActionFires() async throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let sleeper = ManualBoundarySleeper()
        let recorder = ActionRecorder()
        let scheduler = OneShotBoundaryScheduler(
            clock: FixedClock(instant: now),
            sleeper: sleeper
        )

        scheduler.schedule(at: now.addingTimeInterval(60), tolerance: 1) {
            recorder.record("old")
        }
        _ = try await sleeper.waitForRequest(at: 0)

        scheduler.schedule(at: now.addingTimeInterval(120), tolerance: 1) {
            recorder.record("new")
        }
        _ = try await sleeper.waitForRequest(at: 1)
        await sleeper.resumeRequest(at: 1)
        await waitForMainActorTurn()

        let cancelledCount = await sleeper.cancelledRequestCount
        XCTAssertEqual(recorder.values, ["new"])
        XCTAssertFalse(scheduler.hasScheduledBoundary)
        XCTAssertEqual(cancelledCount, 1)
    }

    @MainActor
    func testExplicitCancellationPreventsCallback() async throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let sleeper = ManualBoundarySleeper()
        let recorder = ActionRecorder()
        let scheduler = OneShotBoundaryScheduler(
            clock: FixedClock(instant: now),
            sleeper: sleeper
        )

        scheduler.schedule(at: now, tolerance: -4) {
            recorder.record("unexpected")
        }
        let request = try await sleeper.waitForRequest(at: 0)
        XCTAssertEqual(request.duration, 0)
        XCTAssertEqual(request.tolerance, 0)

        scheduler.cancel()
        await waitForMainActorTurn()

        let cancelledCount = await sleeper.cancelledRequestCount
        XCTAssertTrue(recorder.values.isEmpty)
        XCTAssertFalse(scheduler.hasScheduledBoundary)
        XCTAssertEqual(cancelledCount, 1)
    }

    @MainActor
    func testDeinitCancelsPendingTask() async throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let sleeper = ManualBoundarySleeper()
        var scheduler: OneShotBoundaryScheduler? = OneShotBoundaryScheduler(
            clock: FixedClock(instant: now),
            sleeper: sleeper
        )
        weak var weakScheduler = scheduler

        scheduler?.schedule(at: now.addingTimeInterval(60), tolerance: 1) {}
        _ = try await sleeper.waitForRequest(at: 0)
        scheduler = nil
        await waitForMainActorTurn()

        let cancelledCount = await sleeper.cancelledRequestCount
        XCTAssertNil(weakScheduler)
        XCTAssertEqual(cancelledCount, 1)
    }

    @MainActor
    private func waitForMainActorTurn() async {
        await Task.yield()
        await Task.yield()
    }
}

private actor ManualBoundarySleeper: BoundarySleeping {
    struct Request: Sendable {
        let duration: TimeInterval
        let tolerance: TimeInterval
    }

    private struct PendingRequest {
        let request: Request
        let continuation: CheckedContinuation<Void, any Error>
    }

    private var pending: [UUID: PendingRequest] = [:]
    private var orderedIDs: [UUID] = []
    private(set) var cancelledRequestCount = 0

    func sleep(for duration: TimeInterval, tolerance: TimeInterval) async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                orderedIDs.append(id)
                pending[id] = PendingRequest(
                    request: Request(duration: duration, tolerance: tolerance),
                    continuation: continuation
                )
            }
        } onCancel: {
            Task {
                await self.cancel(id: id)
            }
        }
    }

    func waitForRequest(at index: Int) async throws -> Request {
        for _ in 0..<100 {
            if orderedIDs.indices.contains(index),
               let pendingRequest = pending[orderedIDs[index]] {
                return pendingRequest.request
            }
            await Task.yield()
        }
        throw TestSleeperError.requestDidNotArrive(index)
    }

    func resumeRequest(at index: Int) {
        guard orderedIDs.indices.contains(index),
              let request = pending.removeValue(forKey: orderedIDs[index])
        else {
            return
        }
        request.continuation.resume()
    }

    private func cancel(id: UUID) {
        guard let request = pending.removeValue(forKey: id) else {
            return
        }
        cancelledRequestCount += 1
        request.continuation.resume(throwing: CancellationError())
    }
}

@MainActor
private final class ActionRecorder {
    private(set) var values: [String] = []

    func record(_ value: String) {
        values.append(value)
    }
}

private enum TestSleeperError: Error {
    case requestDidNotArrive(Int)
}
