public struct MonthGridCell: Identifiable, Equatable, Sendable {
    public var id: SolarDate { solarDate }

    public let solarDate: SolarDate
    public let lunarDate: LunarDate
    public let isInDisplayedMonth: Bool
    public let isToday: Bool

    public init(
        solarDate: SolarDate,
        lunarDate: LunarDate,
        isInDisplayedMonth: Bool,
        isToday: Bool
    ) {
        self.solarDate = solarDate
        self.lunarDate = lunarDate
        self.isInDisplayedMonth = isInDisplayedMonth
        self.isToday = isToday
    }
}
