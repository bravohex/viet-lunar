/// A paired heavenly stem and earthly branch.
public struct StemBranch: Hashable, Codable, Sendable, CustomStringConvertible {
    public let stem: HeavenlyStem
    public let branch: EarthlyBranch

    public init(stem: HeavenlyStem, branch: EarthlyBranch) {
        self.stem = stem
        self.branch = branch
    }

    public var description: String {
        "\(stem.vietnameseName) \(branch.vietnameseName)"
    }
}
