import Foundation

public struct LocalTime: Hashable, Codable, Sendable, Comparable {
    public let hour: Int
    public let minute: Int

    public init(validatingHour hour: Int, minute: Int) throws {
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            throw DateValidationError.invalidLocalTime(hour: hour, minute: minute)
        }

        self.hour = hour
        self.minute = minute
    }

    public static func valid(hour: Int, minute: Int) -> Self? {
        try? Self(validatingHour: hour, minute: minute)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            validatingHour: container.decode(Int.self, forKey: .hour),
            minute: container.decode(Int.self, forKey: .minute)
        )
    }
}
