public struct CalendarSnapshotFactory: Sendable {
    private let lunarEngine: any LunarCalendarCalculating
    private let canChiCalculator: CanChiCalculator
    private let clock: any Clock
    private let boundaryPolicy: CanChiDayBoundaryPolicy

    public init(
        lunarEngine: any LunarCalendarCalculating,
        canChiCalculator: CanChiCalculator = CanChiCalculator(),
        clock: any Clock,
        boundaryPolicy: CanChiDayBoundaryPolicy = .defaultValue
    ) {
        self.lunarEngine = lunarEngine
        self.canChiCalculator = canChiCalculator
        self.clock = clock
        self.boundaryPolicy = boundaryPolicy
    }

    public func makeSnapshot() throws -> CalendarSnapshot {
        let instant = clock.now()
        let localDateTime = VietnamCalendarTime.localDateTime(containing: instant)
        let solarDate = localDateTime.solarDate
        let localTime = localDateTime.localTime
        let lunarDate = try lunarEngine.lunarDate(for: solarDate)

        return CalendarSnapshot(
            instant: instant,
            solarDate: solarDate,
            lunarDate: lunarDate,
            yearCanChi: canChiCalculator.year(forLunarYear: lunarDate.year),
            monthCanChi: canChiCalculator.month(for: lunarDate),
            dayCanChi: canChiCalculator.day(
                for: solarDate,
                at: localTime,
                boundaryPolicy: boundaryPolicy
            ),
            hourCanChi: canChiCalculator.hour(
                for: solarDate,
                at: localTime,
                boundaryPolicy: boundaryPolicy
            )
        )
    }
}
