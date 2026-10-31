import Foundation

/// How a day on a holiday calendar should be presented.
public enum HolidayKind: String, Hashable, Codable, Sendable {
    /// A public holiday: the day number is highlighted in the month grid.
    case official
    /// A commemorative day that does not change the working calendar.
    case observance
}

/// One entry of a holiday calendar, covering `dayCount` consecutive days.
public struct HolidayEvent: Hashable, Sendable {
    public let name: String
    public let kind: HolidayKind
    public let firstDate: SolarDate
    public let dayCount: Int

    public init(
        name: String,
        kind: HolidayKind,
        firstDate: SolarDate,
        dayCount: Int = 1
    ) {
        self.name = name
        self.kind = kind
        self.firstDate = firstDate
        self.dayCount = max(1, dayCount)
    }

    public var lastDate: SolarDate {
        let lastJDN = GregorianJDN.jdn(for: firstDate) + dayCount - 1
        return (try? GregorianJDN.solarDate(forJDN: lastJDN)) ?? firstDate
    }
}

/// The events of a single imported or bundled calendar file.
public struct HolidayCalendar: Hashable, Sendable {
    public let name: String?
    public let events: [HolidayEvent]

    public init(name: String?, events: [HolidayEvent]) {
        self.name = name
        self.events = events
    }

    /// First and last year touched by any event, or nil for an empty calendar.
    public var yearRange: ClosedRange<Int>? {
        guard let first = events.map(\.firstDate.year).min(),
              let last = events.map(\.lastDate.year).max()
        else {
            return nil
        }

        return first...last
    }
}

/// A selectable calendar: the bundled default or a file the user imported.
public struct HolidaySource: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let isBuiltIn: Bool
    public let calendar: HolidayCalendar

    public init(
        id: String,
        name: String,
        isBuiltIn: Bool,
        calendar: HolidayCalendar
    ) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.calendar = calendar
    }
}

/// A holiday as it applies to one particular day.
public struct HolidayOccurrence: Hashable, Sendable {
    public let name: String
    public let kind: HolidayKind
    /// 1-based position of the day inside a multi-day event.
    public let dayNumber: Int
    public let dayCount: Int

    public init(name: String, kind: HolidayKind, dayNumber: Int, dayCount: Int) {
        self.name = name
        self.kind = kind
        self.dayNumber = dayNumber
        self.dayCount = dayCount
    }
}

/// Day-indexed lookup built once from a calendar.
public struct HolidayIndex: Sendable {
    public static let empty = HolidayIndex(calendar: HolidayCalendar(name: nil, events: []))

    private let occurrencesByJDN: [Int: [HolidayOccurrence]]

    public init(calendar: HolidayCalendar) {
        var table: [Int: [HolidayOccurrence]] = [:]

        for event in calendar.events {
            let startJDN = GregorianJDN.jdn(for: event.firstDate)
            for offset in 0..<event.dayCount {
                table[startJDN + offset, default: []].append(
                    HolidayOccurrence(
                        name: event.name,
                        kind: event.kind,
                        dayNumber: offset + 1,
                        dayCount: event.dayCount
                    )
                )
            }
        }

        occurrencesByJDN = table.mapValues { occurrences in
            occurrences.sorted { lhs, rhs in
                if lhs.kind != rhs.kind {
                    return lhs.kind == .official
                }
                if lhs.name != rhs.name {
                    return lhs.name < rhs.name
                }
                return lhs.dayNumber < rhs.dayNumber
            }
        }
    }

    /// Holidays on `date`, official ones first, then by name.
    public func occurrences(on date: SolarDate) -> [HolidayOccurrence] {
        occurrencesByJDN[GregorianJDN.jdn(for: date)] ?? []
    }

    public func isOfficialHoliday(on date: SolarDate) -> Bool {
        occurrences(on: date).contains { $0.kind == .official }
    }
}
