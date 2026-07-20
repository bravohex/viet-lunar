public enum WeekStart: String, CaseIterable, Codable, Sendable {
    case monday
    case sunday

    public static let defaultValue: Self = .monday

    public var vietnameseName: String {
        switch self {
        case .monday:
            CoreLocalization.text("week_start.monday", fallback: "Thứ Hai")
        case .sunday:
            CoreLocalization.text("week_start.sunday", fallback: "Chủ Nhật")
        }
    }
}
