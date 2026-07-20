import Foundation

public protocol Clock: Sendable {
    func now() -> Date
}

public struct SystemClock: Clock {
    public init() {}

    public func now() -> Date {
        Date()
    }
}

public struct FixedClock: Clock {
    public let instant: Date

    public init(instant: Date) {
        self.instant = instant
    }

    public func now() -> Date {
        instant
    }
}
