import Foundation
import VietLunarCore

public protocol BoundarySleeping: Sendable {
    func sleep(for duration: TimeInterval, tolerance: TimeInterval) async throws
}

public struct ContinuousBoundarySleeper: BoundarySleeping {
    public init() {}

    public func sleep(for duration: TimeInterval, tolerance: TimeInterval) async throws {
        try await Task<Never, Never>.sleep(
            for: .seconds(max(0, duration)),
            tolerance: .seconds(max(0, tolerance))
        )
    }
}

@MainActor
public protocol BoundaryScheduling: AnyObject, Sendable {
    var hasScheduledBoundary: Bool { get }

    func schedule(
        at boundary: Date,
        tolerance: TimeInterval,
        action: @escaping @MainActor @Sendable () -> Void
    )
    func cancel()
}

@MainActor
public final class OneShotBoundaryScheduler: BoundaryScheduling {
    public private(set) var hasScheduledBoundary = false

    private let clock: any Clock
    private let sleeper: any BoundarySleeping
    private var scheduledTask: Task<Void, Never>?

    public init(
        clock: any Clock = SystemClock(),
        sleeper: any BoundarySleeping = ContinuousBoundarySleeper()
    ) {
        self.clock = clock
        self.sleeper = sleeper
    }

    deinit {
        scheduledTask?.cancel()
    }

    public func schedule(
        at boundary: Date,
        tolerance: TimeInterval = 1,
        action: @escaping @MainActor @Sendable () -> Void
    ) {
        cancel()

        let delay = max(0, boundary.timeIntervalSince(clock.now()))
        let sleeper = self.sleeper
        hasScheduledBoundary = true
        scheduledTask = Task { [weak self] in
            do {
                try await sleeper.sleep(
                    for: delay,
                    tolerance: max(0, tolerance)
                )
            } catch {
                return
            }

            guard !Task.isCancelled, let self else {
                return
            }
            scheduledTask = nil
            hasScheduledBoundary = false
            action()
        }
    }

    public func cancel() {
        scheduledTask?.cancel()
        scheduledTask = nil
        hasScheduledBoundary = false
    }
}
