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

    public func day(
        for solarDate: SolarDate,
        at localTime: LocalTime,
        boundaryPolicy: CanChiDayBoundaryPolicy = .defaultValue
    ) -> StemBranch {
        let civilJDN = GregorianJDN.jdn(for: solarDate)
        let effectiveJDN: Int

        switch boundaryPolicy {
        case .civilMidnight:
            effectiveJDN = civilJDN
        case .startOfZiHour:
            effectiveJDN = localTime.hour == 23 ? civilJDN + 1 : civilJDN
        }

        return day(forJDN: effectiveJDN)
    }

    public func day(forJDN jdn: Int) -> StemBranch {
        stemBranch(
            stemIndex: floorMod(jdn + 9, 10),
            branchIndex: floorMod(jdn + 1, 12)
        )
    }

    public func hour(
        for solarDate: SolarDate,
        at localTime: LocalTime,
        boundaryPolicy: CanChiDayBoundaryPolicy = .defaultValue
    ) -> StemBranch {
        let hourBranchIndex = floorMod((localTime.hour + 1) / 2, 12)
        let effectiveDayStem = day(
            for: solarDate,
            at: localTime,
            boundaryPolicy: boundaryPolicy
        ).stem.rawValue

        return stemBranch(
            stemIndex: floorMod((effectiveDayStem * 2) + hourBranchIndex, 10),
            branchIndex: hourBranchIndex
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
