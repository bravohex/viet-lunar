public enum GregorianJDNError: Error, Equatable, Sendable {
    case invalidJDN(Int)
}

public enum GregorianJDN: Sendable {
    /// Returns the Julian Day Number whose civil-day label matches the
    /// proleptic Gregorian date. Under the conventional noon-based JDN
    /// numbering, 2000-01-01 maps to 2_451_545.
    public static func jdn(for date: SolarDate) -> Int {
        let adjustment = (14 - date.month) / 12
        let adjustedYear = date.year + 4_800 - adjustment
        let adjustedMonth = date.month + (12 * adjustment) - 3

        return date.day
            + ((153 * adjustedMonth + 2) / 5)
            + (365 * adjustedYear)
            + (adjustedYear / 4)
            - (adjustedYear / 100)
            + (adjustedYear / 400)
            - 32_045
    }

    public static func solarDate(forJDN jdn: Int) throws -> SolarDate {
        guard (1_721_426...5_373_484).contains(jdn) else {
            throw GregorianJDNError.invalidJDN(jdn)
        }

        let shifted = jdn + 32_044
        let century = (4 * shifted + 3) / 146_097
        let dayInCentury = shifted - ((146_097 * century) / 4)
        let yearInCentury = (4 * dayInCentury + 3) / 1_461
        let dayInYear = dayInCentury - ((1_461 * yearInCentury) / 4)
        let monthIndex = (5 * dayInYear + 2) / 153

        let day = dayInYear - ((153 * monthIndex + 2) / 5) + 1
        let month = monthIndex + 3 - (12 * (monthIndex / 10))
        let year = (100 * century) + yearInCentury - 4_800 + (monthIndex / 10)

        guard let date = SolarDate.valid(year: year, month: month, day: day) else {
            throw GregorianJDNError.invalidJDN(jdn)
        }

        return date
    }
}
