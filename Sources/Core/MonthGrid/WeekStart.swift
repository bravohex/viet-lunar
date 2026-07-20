public enum WeekStart: String, CaseIterable, Codable, Sendable {
    case monday
    case sunday

    public static let defaultValue: Self = .monday
}
