public enum DateValidationError: Error, Equatable, Sendable {
    case invalidSolarDate(year: Int, month: Int, day: Int)
    case invalidLunarDate(year: Int, month: Int, day: Int)
    case invalidYearMonth(year: Int, month: Int)
    case invalidLocalTime(hour: Int, minute: Int)
}
