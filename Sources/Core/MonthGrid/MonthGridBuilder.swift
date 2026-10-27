public struct MonthGridBuilder: Sendable {
    public static let cellCount = 42

    private let lunarEngine: any LunarCalendarCalculating

    public init(lunarEngine: any LunarCalendarCalculating) {
        self.lunarEngine = lunarEngine
    }

    public func build(
        displayedMonth: YearMonth,
        weekStart: WeekStart,
        today: SolarDate
    ) throws -> [MonthGridCell] {
        let firstDay = try SolarDate(
            validatingYear: displayedMonth.year,
            month: displayedMonth.month,
            day: 1
        )
        guard lunarEngine.supportedSolarRange.contains(firstDay) else {
            throw LunarCalendarError.unsupportedSolarDate(firstDay)
        }
        let firstDayJDN = GregorianJDN.jdn(for: firstDay)
        let leadingDayCount = leadingDayCount(
            firstDayJDN: firstDayJDN,
            weekStart: weekStart
        )
        let gridStartJDN = firstDayJDN - leadingDayCount

        var cells: [MonthGridCell] = []
        cells.reserveCapacity(Self.cellCount)

        for offset in 0..<Self.cellCount {
            let solarDate = try GregorianJDN.solarDate(forJDN: gridStartJDN + offset)
            // Boundary padding is blank in the UI, not a failed supported month.
            guard lunarEngine.supportedSolarRange.contains(solarDate) else { continue }
            let lunarDate = try lunarEngine.lunarDate(for: solarDate)
            cells.append(
                MonthGridCell(
                    solarDate: solarDate,
                    lunarDate: lunarDate,
                    isInDisplayedMonth: solarDate.year == displayedMonth.year
                        && solarDate.month == displayedMonth.month,
                    isToday: solarDate == today
                )
            )
        }

        return cells
    }

    private func leadingDayCount(firstDayJDN: Int, weekStart: WeekStart) -> Int {
        let mondayBasedIndex = floorMod(firstDayJDN, 7)

        switch weekStart {
        case .monday:
            return mondayBasedIndex
        case .sunday:
            return floorMod(mondayBasedIndex + 1, 7)
        }
    }
}
