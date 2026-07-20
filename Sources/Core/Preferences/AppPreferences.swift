import Foundation

public struct AppPreferences: Equatable, Codable, Sendable {
    public var titleFormat: MenuBarTitleFormat
    public var showsClock: Bool
    public var weekStart: WeekStart
    public var uses24HourClock: Bool
    public var canChiBoundaryPolicy: CanChiDayBoundaryPolicy

    public init(
        titleFormat: MenuBarTitleFormat,
        showsClock: Bool,
        weekStart: WeekStart,
        uses24HourClock: Bool,
        canChiBoundaryPolicy: CanChiDayBoundaryPolicy
    ) {
        self.titleFormat = titleFormat
        self.showsClock = showsClock
        self.weekStart = weekStart
        self.uses24HourClock = uses24HourClock
        self.canChiBoundaryPolicy = canChiBoundaryPolicy
    }

    public static let defaultValue = Self(
        titleFormat: .defaultValue,
        showsClock: false,
        weekStart: .defaultValue,
        uses24HourClock: true,
        canChiBoundaryPolicy: .defaultValue
    )

    public func refreshRequirements(
        displayedClockTimeZone: TimeZone
    ) -> RefreshRequirements {
        var granularities: Set<RefreshGranularity> = [.vietnamMidnight]
        if showsClock {
            granularities.insert(.minute)
        }
        return RefreshRequirements(
            granularities: granularities,
            displayedClockTimeZone: displayedClockTimeZone
        )
    }
}
