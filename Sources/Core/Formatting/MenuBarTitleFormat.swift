public enum MenuBarTitleFormat: String, CaseIterable, Codable, Sendable {
    case lunarDate
    case solarAndLunar
    case lunarAndDayCanChi
    case solarLunarAndDayCanChi
    case iconOnly

    public static let defaultValue: Self = .lunarDate

    public var vietnameseName: String {
        switch self {
        case .lunarDate:
            CoreLocalization.text("title_format.lunar", fallback: "Ngày âm")
        case .solarAndLunar:
            CoreLocalization.text(
                "title_format.solar_lunar",
                fallback: "Ngày dương và ngày âm"
            )
        case .lunarAndDayCanChi:
            CoreLocalization.text(
                "title_format.lunar_can_chi",
                fallback: "Ngày âm và Can–Chi"
            )
        case .solarLunarAndDayCanChi:
            CoreLocalization.text(
                "title_format.solar_lunar_can_chi",
                fallback: "Ngày dương, ngày âm và Can–Chi"
            )
        case .iconOnly:
            CoreLocalization.text("title_format.icon", fallback: "Chỉ biểu tượng")
        }
    }

    public var includesSolarDate: Bool {
        switch self {
        case .solarAndLunar, .solarLunarAndDayCanChi:
            true
        case .lunarDate, .lunarAndDayCanChi, .iconOnly:
            false
        }
    }

    public var includesDayCanChi: Bool {
        switch self {
        case .lunarAndDayCanChi, .solarLunarAndDayCanChi:
            true
        case .lunarDate, .solarAndLunar, .iconOnly:
            false
        }
    }

    public var isIconOnly: Bool {
        self == .iconOnly
    }

    public func withSolarDate(_ isIncluded: Bool) -> Self {
        guard !isIconOnly else {
            return self
        }
        return Self.textFormat(
            includesSolarDate: isIncluded,
            includesDayCanChi: includesDayCanChi
        )
    }

    public func withDayCanChi(_ isIncluded: Bool) -> Self {
        guard !isIconOnly else {
            return self
        }
        return Self.textFormat(
            includesSolarDate: includesSolarDate,
            includesDayCanChi: isIncluded
        )
    }

    private static func textFormat(
        includesSolarDate: Bool,
        includesDayCanChi: Bool
    ) -> Self {
        switch (includesSolarDate, includesDayCanChi) {
        case (false, false): .lunarDate
        case (true, false): .solarAndLunar
        case (false, true): .lunarAndDayCanChi
        case (true, true): .solarLunarAndDayCanChi
        }
    }
}
