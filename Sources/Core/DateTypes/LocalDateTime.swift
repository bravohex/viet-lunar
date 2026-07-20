/// Gregorian civil date and wall-clock time under an explicit time-zone policy.
public struct LocalDateTime: Hashable, Codable, Sendable {
    public let solarDate: SolarDate
    public let localTime: LocalTime

    public init(solarDate: SolarDate, localTime: LocalTime) {
        self.solarDate = solarDate
        self.localTime = localTime
    }
}
