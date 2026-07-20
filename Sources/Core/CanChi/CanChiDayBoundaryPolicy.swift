/// Defines when the displayed sexagenary day advances near midnight.
public enum CanChiDayBoundaryPolicy: String, CaseIterable, Codable, Sendable {
    /// The day advances with the Gregorian civil date at 00:00.
    case civilMidnight

    /// The day advances at the beginning of the Tý interval at 23:00.
    case startOfZiHour

    public static let defaultValue: Self = .civilMidnight
}
