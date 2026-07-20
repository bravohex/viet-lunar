public enum WeekStart: String, CaseIterable, Codable, Sendable {
    case monday
    case sunday

    public static let defaultValue: Self = .monday

    public var vietnameseName: String {
        switch self {
        case .monday: "Thứ Hai"
        case .sunday: "Chủ Nhật"
        }
    }
}
