import Foundation

public enum RefreshGranularity: Hashable, Sendable {
    case vietnamMidnight
    case canChiHour
    case minute
}

public struct RefreshRequirements: Equatable, Sendable {
    public let granularities: Set<RefreshGranularity>
    public let displayedClockTimeZone: TimeZone

    public init(
        granularities: Set<RefreshGranularity>,
        displayedClockTimeZone: TimeZone = .current
    ) {
        self.granularities = granularities
        self.displayedClockTimeZone = displayedClockTimeZone
    }

    public static let lunarDateOnly = Self(
        granularities: [.vietnamMidnight],
        displayedClockTimeZone: VietnamCalendarTime.timeZone
    )

    public static let canChiHour = Self(
        granularities: [.canChiHour],
        displayedClockTimeZone: VietnamCalendarTime.timeZone
    )

    public static func minute(in timeZone: TimeZone) -> Self {
        Self(granularities: [.minute], displayedClockTimeZone: timeZone)
    }
}

public enum BoundaryCalculationError: Error, Equatable, Sendable {
    case noRequirements
    case boundaryNotFound(RefreshGranularity)
}

public protocol BoundaryCalculating: Sendable {
    func nextBoundary(
        after instant: Date,
        requirements: RefreshRequirements
    ) throws -> Date
}

public struct BoundaryCalculator: BoundaryCalculating {
    public init() {}

    public func nextBoundary(
        after instant: Date,
        requirements: RefreshRequirements
    ) throws -> Date {
        guard !requirements.granularities.isEmpty else {
            throw BoundaryCalculationError.noRequirements
        }

        let candidates = try requirements.granularities.map { granularity in
            switch granularity {
            case .vietnamMidnight:
                try nextVietnamMidnight(after: instant)
            case .canChiHour:
                try nextCanChiHourBoundary(after: instant)
            case .minute:
                try nextMinuteBoundary(
                    after: instant,
                    timeZone: requirements.displayedClockTimeZone
                )
            }
        }

        guard let next = candidates.min() else {
            throw BoundaryCalculationError.noRequirements
        }
        return next
    }

    private func nextVietnamMidnight(after instant: Date) throws -> Date {
        try nextMatchingBoundary(
            after: instant,
            timeZone: VietnamCalendarTime.timeZone,
            components: DateComponents(hour: 0, minute: 0, second: 0),
            granularity: .vietnamMidnight
        )
    }

    private func nextCanChiHourBoundary(after instant: Date) throws -> Date {
        let calendar = gregorianCalendar(timeZone: VietnamCalendarTime.timeZone)
        let boundaryHours = [0, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]
        let candidates = boundaryHours.compactMap { hour in
            calendar.nextDate(
                after: instant,
                matching: DateComponents(hour: hour, minute: 0, second: 0),
                matchingPolicy: .nextTime,
                repeatedTimePolicy: .first,
                direction: .forward
            )
        }

        guard let next = candidates.min() else {
            throw BoundaryCalculationError.boundaryNotFound(.canChiHour)
        }
        return next
    }

    private func nextMinuteBoundary(
        after instant: Date,
        timeZone: TimeZone
    ) throws -> Date {
        try nextMatchingBoundary(
            after: instant,
            timeZone: timeZone,
            components: DateComponents(second: 0),
            granularity: .minute
        )
    }

    private func nextMatchingBoundary(
        after instant: Date,
        timeZone: TimeZone,
        components: DateComponents,
        granularity: RefreshGranularity
    ) throws -> Date {
        let calendar = gregorianCalendar(timeZone: timeZone)
        guard let next = calendar.nextDate(
            after: instant,
            matching: components,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ) else {
            throw BoundaryCalculationError.boundaryNotFound(granularity)
        }
        return next
    }

    private func gregorianCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        return calendar
    }
}
