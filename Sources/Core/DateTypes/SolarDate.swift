import Foundation

public struct SolarDate: Hashable, Codable, Sendable, Comparable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(validatingYear year: Int, month: Int, day: Int) throws {
        guard Self.isValid(year: year, month: month, day: day) else {
            throw DateValidationError.invalidSolarDate(year: year, month: month, day: day)
        }

        self.year = year
        self.month = month
        self.day = day
    }

    public static func valid(year: Int, month: Int, day: Int) -> Self? {
        try? Self(validatingYear: year, month: month, day: day)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    public static func isLeapYear(_ year: Int) -> Bool {
        year.isMultiple(of: 400) || (year.isMultiple(of: 4) && !year.isMultiple(of: 100))
    }

    public static func daysInMonth(year: Int, month: Int) -> Int? {
        guard (1...12).contains(month) else {
            return nil
        }

        switch month {
        case 2:
            return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }

    private static func isValid(year: Int, month: Int, day: Int) -> Bool {
        guard (1...9_999).contains(year),
              let monthLength = daysInMonth(year: year, month: month)
        else {
            return false
        }

        return (1...monthLength).contains(day)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            validatingYear: container.decode(Int.self, forKey: .year),
            month: container.decode(Int.self, forKey: .month),
            day: container.decode(Int.self, forKey: .day)
        )
    }
}
