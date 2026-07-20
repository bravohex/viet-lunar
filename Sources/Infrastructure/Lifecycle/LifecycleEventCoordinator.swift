@MainActor
public final class LifecycleEventCoordinator {
    private let source: any LifecycleEventSourcing
    private let refresh: @MainActor @Sendable () -> Void
    private var eventTask: Task<Void, Never>?
    private var coalescedRefreshTask: Task<Void, Never>?
    private var isStopped = false

    public init(
        source: any LifecycleEventSourcing,
        refresh: @escaping @MainActor @Sendable () -> Void
    ) {
        self.source = source
        self.refresh = refresh
    }

    deinit {
        eventTask?.cancel()
        coalescedRefreshTask?.cancel()
    }

    public func start() {
        guard eventTask == nil, !isStopped else {
            return
        }

        let events = source.events()
        eventTask = Task { [weak self] in
            for await _ in events {
                guard !Task.isCancelled, let self else {
                    return
                }
                requestCoalescedRefresh()
            }
        }
    }

    public func stop() {
        isStopped = true
        eventTask?.cancel()
        eventTask = nil
        coalescedRefreshTask?.cancel()
        coalescedRefreshTask = nil
    }

    private func requestCoalescedRefresh() {
        guard coalescedRefreshTask == nil else {
            return
        }

        coalescedRefreshTask = Task { [weak self] in
            await Task.yield()
            guard !Task.isCancelled, let self else {
                return
            }
            coalescedRefreshTask = nil
            refresh()
        }
    }
}
