import Foundation

public struct CalendarSnapshot: Equatable, Sendable {
    public let instant: Date
    public let solarDate: SolarDate
    public let lunarDate: LunarDate
    public let yearCanChi: StemBranch
    public let monthCanChi: StemBranch
    public let dayCanChi: StemBranch
    public let hourCanChi: StemBranch

    public init(
        instant: Date,
        solarDate: SolarDate,
        lunarDate: LunarDate,
        yearCanChi: StemBranch,
        monthCanChi: StemBranch,
        dayCanChi: StemBranch,
        hourCanChi: StemBranch
    ) {
        self.instant = instant
        self.solarDate = solarDate
        self.lunarDate = lunarDate
        self.yearCanChi = yearCanChi
        self.monthCanChi = monthCanChi
        self.dayCanChi = dayCanChi
        self.hourCanChi = hourCanChi
    }
}
