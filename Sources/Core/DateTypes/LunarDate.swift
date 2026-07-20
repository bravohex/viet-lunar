import Foundation

public struct LunarDate: Hashable, Codable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let isLeapMonth: Bool

    public init(
        validatingYear year: Int,
        month: Int,
        day: Int,
        isLeapMonth: Bool
    ) throws {
        guard (1...9_999).contains(year),
              (1...12).contains(month),
              (1...30).contains(day)
        else {
            throw DateValidationError.invalidLunarDate(year: year, month: month, day: day)
        }

        self.year = year
        self.month = month
        self.day = day
        self.isLeapMonth = isLeapMonth
    }

    public static func valid(
        year: Int,
        month: Int,
        day: Int,
        isLeapMonth: Bool = false
    ) -> Self? {
        try? Self(
            validatingYear: year,
            month: month,
            day: day,
            isLeapMonth: isLeapMonth
        )
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            validatingYear: container.decode(Int.self, forKey: .year),
            month: container.decode(Int.self, forKey: .month),
            day: container.decode(Int.self, forKey: .day),
            isLeapMonth: container.decode(Bool.self, forKey: .isLeapMonth)
        )
    }
}
