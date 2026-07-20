@inline(__always)
func floorMod(_ value: Int, _ modulus: Int) -> Int {
    let remainder = value % modulus
    return remainder >= 0 ? remainder : remainder + modulus
}

/// Calculates Vietnamese Can–Chi values from validated calendar inputs.
public struct CanChiCalculator: Sendable {
    public init() {}

    public func year(forLunarYear year: Int) -> StemBranch {
        stemBranch(
            stemIndex: floorMod(year + 6, 10),
            branchIndex: floorMod(year + 8, 12)
        )
    }

    public func month(for lunarDate: LunarDate) -> StemBranch {
        month(forLunarYear: lunarDate.year, month: lunarDate.month)
    }

    public func month(forLunarYear year: Int, month: Int) -> StemBranch {
        stemBranch(
            stemIndex: floorMod((year * 12) + month + 3, 10),
            branchIndex: floorMod(month + 1, 12)
        )
    }

    public func day(for solarDate: SolarDate) -> StemBranch {
        day(forJDN: GregorianJDN.jdn(for: solarDate))
    }

    public func day(forJDN jdn: Int) -> StemBranch {
        stemBranch(
            stemIndex: floorMod(jdn + 9, 10),
            branchIndex: floorMod(jdn + 1, 12)
        )
    }

    private func stemBranch(stemIndex: Int, branchIndex: Int) -> StemBranch {
        guard
            let stem = HeavenlyStem(rawValue: stemIndex),
            let branch = EarthlyBranch(rawValue: branchIndex)
        else {
            preconditionFailure("Can–Chi indexes must be normalized before lookup")
        }

        return StemBranch(stem: stem, branch: branch)
    }
}
