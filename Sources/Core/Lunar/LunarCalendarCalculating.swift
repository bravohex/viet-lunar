public protocol LunarCalendarCalculating: Sendable {
    var supportedSolarRange: ClosedRange<SolarDate> { get }

    func lunarDate(for solarDate: SolarDate) throws -> LunarDate
    func solarDate(for lunarDate: LunarDate) throws -> SolarDate
    func monthLength(year: Int, month: Int, isLeapMonth: Bool) throws -> Int
    func leapMonth(inLunarYear year: Int) throws -> Int?
}

public enum LunarCalendarError: Error, Equatable, Sendable {
    case invalidSolarDate(SolarDate)
    case invalidLunarDate(LunarDate)
    case unsupportedSolarDate(SolarDate)
    case unsupportedLunarYear(Int)
    case invalidLeapMonth(requested: Int, actual: Int?)
    case dayExceedsMonthLength(day: Int, length: Int)
    case corruptedTable(year: Int, reason: String)
}
