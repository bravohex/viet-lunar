import Foundation

/// A compact visual classification for a traditional calendar day.
///
/// The classification is cultural-reference information only. It does not
/// assess a person's age, activity, or expected outcome.
public enum TraditionalDayClassification: String, Hashable, Codable, Sendable {
    case auspicious
    case inauspicious
    case ordinary
}

/// Classifies a civil date from its lunar month and canonical day branch.
///
/// The month-grid convention intentionally presents four traditional
/// auspicious branches, four inauspicious branches, and four ordinary branches
/// for each lunar-month group. This is a compact visual summary rather than a
/// comprehensive date-selection system.
public enum TraditionalDayClassifier: Sendable {
    public static func classification(
        for lunarDate: LunarDate,
        solarDate: SolarDate
    ) -> TraditionalDayClassification {
        classification(
            lunarMonth: lunarDate.month,
            dayBranch: CanChiCalculator().day(for: solarDate).branch
        )
    }

    public static func classification(
        lunarMonth: Int,
        dayBranch: EarthlyBranch
    ) -> TraditionalDayClassification {
        precondition(
            (1...12).contains(lunarMonth),
            "Lunar month must be in 1...12"
        )

        let monthGroupIndex = (lunarMonth - 1) % 6

        if auspiciousBranches[monthGroupIndex].contains(dayBranch) {
            return .auspicious
        }
        if inauspiciousBranches[monthGroupIndex].contains(dayBranch) {
            return .inauspicious
        }
        return .ordinary
    }

    private static let auspiciousBranches: [[EarthlyBranch]] = [
        [.ty, .suu, .tySnake, .mui],
        [.dan, .mao, .mui, .dau],
        [.thin, .tySnake, .dau, .hoi],
        [.ngo, .mui, .hoi, .suu],
        [.than, .dau, .suu, .mao],
        [.tuat, .hoi, .mao, .tySnake]
    ]

    private static let inauspiciousBranches: [[EarthlyBranch]] = [
        [.ngo, .mao, .hoi, .dau],
        [.than, .tySnake, .suu, .hoi],
        [.tuat, .mui, .suu, .mao],
        [.ty, .dau, .tySnake, .mao],
        [.dan, .hoi, .mui, .tySnake],
        [.thin, .suu, .dau, .mui]
    ]
}
