public enum MenuBarTitleFormat: String, CaseIterable, Codable, Sendable {
    case lunarDate
    case solarAndLunar
    case lunarAndDayCanChi
    case solarLunarAndDayCanChi
    case iconOnly

    public static let defaultValue: Self = .lunarDate

    public var vietnameseName: String {
        switch self {
        case .lunarDate: "Ngày âm"
        case .solarAndLunar: "Ngày dương và ngày âm"
        case .lunarAndDayCanChi: "Ngày âm và Can–Chi"
        case .solarLunarAndDayCanChi: "Ngày dương, ngày âm và Can–Chi"
        case .iconOnly: "Chỉ biểu tượng"
        }
    }
}
