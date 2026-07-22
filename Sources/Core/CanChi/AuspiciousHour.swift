import Foundation

/// A traditional auspicious two-hour interval identified by its earthly branch.
///
/// This is reference information only. It does not assess a person's age,
/// activity, or outcome.
public struct AuspiciousHour: Hashable, Codable, Sendable, CustomStringConvertible {
    public let branch: EarthlyBranch

    public init(branch: EarthlyBranch) {
        self.branch = branch
    }

    /// Civil start hour in the canonical Vietnamese time zone.
    ///
    /// The Tý interval starts at 23:00; every other branch begins at an odd
    /// hour and lasts until the end of the following hour.
    public var civilStartHour: Int {
        (branch.rawValue * 2 + 23) % 24
    }

    /// Civil end hour for the displayed inclusive interval.
    public var civilEndHour: Int {
        (civilStartHour + 1) % 24
    }

    /// Vietnamese 24-hour presentation, for example `23:00–00:59`.
    public var civilTimeRange: String {
        String(
            format: "%02d:00–%02d:59",
            locale: Locale(identifier: "vi"),
            civilStartHour,
            civilEndHour
        )
    }

    public var description: String {
        "\(branch.vietnameseName) (\(civilTimeRange))"
    }
}

/// Looks up the six traditional auspicious-hour intervals for a day branch.
///
/// The mapping is a compact, static cultural-reference table. It intentionally
/// uses only the day branch and does not make personalised recommendations.
public enum AuspiciousHourCalculator: Sendable {
    public static func hours(for dayBranch: EarthlyBranch) -> [AuspiciousHour] {
        let branches: [EarthlyBranch]

        switch dayBranch {
        case .ty, .ngo:
            branches = [.ty, .suu, .mao, .ngo, .than, .dau]
        case .suu, .mui:
            branches = [.dan, .mao, .tySnake, .than, .tuat, .hoi]
        case .dan, .than:
            branches = [.ty, .suu, .thin, .tySnake, .mui, .tuat]
        case .mao, .dau:
            branches = [.ty, .dan, .mao, .ngo, .mui, .dau]
        case .thin, .tuat:
            branches = [.dan, .thin, .tySnake, .than, .dau, .hoi]
        case .tySnake, .hoi:
            branches = [.suu, .thin, .ngo, .mui, .tuat, .hoi]
        }

        return branches.map { AuspiciousHour(branch: $0) }
    }
}
