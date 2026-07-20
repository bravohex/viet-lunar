import Foundation

public struct YearMonth: Hashable, Codable, Sendable, Comparable {
    public let year: Int
    public let month: Int

    public init(validatingYear year: Int, month: Int) throws {
        guard (1...9_999).contains(year), (1...12).contains(month) else {
            throw DateValidationError.invalidYearMonth(year: year, month: month)
        }

        self.year = year
        self.month = month
    }

    public static func valid(year: Int, month: Int) -> Self? {
        try? Self(validatingYear: year, month: month)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            validatingYear: container.decode(Int.self, forKey: .year),
            month: container.decode(Int.self, forKey: .month)
        )
    }
}
