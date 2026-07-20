public enum LunarYearRecordError: Error, Equatable, Sendable {
    case invalidYear(Int)
    case invalidTetJDN(Int)
    case invalidLeapMonth(Int)
    case invalidMonthLengthBits(UInt16, monthCount: Int)
    case invalidSequentialIndex(Int, monthCount: Int)
    case invalidLogicalMonth(month: Int, isLeap: Bool, actualLeapMonth: Int?)
}

public struct EncodedLunarYearRecord: Equatable, Sendable {
    public let year: Int
    public let tetJDN: Int32
    public let leapMonth: UInt8
    public let monthLengthBits: UInt16

    public var monthCount: Int {
        leapMonth == 0 ? 12 : 13
    }

    public init(
        validatingYear year: Int,
        tetJDN: Int,
        leapMonth: Int,
        monthLengthBits: UInt16
    ) throws {
        guard year > 0 else {
            throw LunarYearRecordError.invalidYear(year)
        }
        guard tetJDN > 0, let encodedTet = Int32(exactly: tetJDN) else {
            throw LunarYearRecordError.invalidTetJDN(tetJDN)
        }
        guard (0...12).contains(leapMonth),
              let encodedLeapMonth = UInt8(exactly: leapMonth)
        else {
            throw LunarYearRecordError.invalidLeapMonth(leapMonth)
        }

        let count = leapMonth == 0 ? 12 : 13
        let validMask = (UInt16(1) << UInt16(count)) - 1
        guard monthLengthBits & ~validMask == 0 else {
            throw LunarYearRecordError.invalidMonthLengthBits(
                monthLengthBits,
                monthCount: count
            )
        }

        self.year = year
        self.tetJDN = encodedTet
        self.leapMonth = encodedLeapMonth
        self.monthLengthBits = monthLengthBits
    }

    internal init(
        uncheckedYear year: Int,
        tetJDN: Int32,
        leapMonth: UInt8,
        monthLengthBits: UInt16
    ) {
        assert(year > 0)
        assert((0...12).contains(leapMonth))
        self.year = year
        self.tetJDN = tetJDN
        self.leapMonth = leapMonth
        self.monthLengthBits = monthLengthBits
    }

    public func monthLength(atSequentialIndex index: Int) throws -> Int {
        try validateSequentialIndex(index)
        return monthLengthBits & (UInt16(1) << UInt16(index)) == 0 ? 29 : 30
    }

    public func logicalMonth(
        atSequentialIndex index: Int
    ) throws -> (month: Int, isLeap: Bool) {
        try validateSequentialIndex(index)

        let leap = Int(leapMonth)
        guard leap > 0 else {
            return (index + 1, false)
        }

        if index < leap {
            return (index + 1, false)
        }
        if index == leap {
            return (leap, true)
        }
        return (index, false)
    }

    public func sequentialIndex(month: Int, isLeap: Bool) throws -> Int {
        let leap = Int(leapMonth)
        guard (1...12).contains(month),
              !isLeap || month == leap
        else {
            throw LunarYearRecordError.invalidLogicalMonth(
                month: month,
                isLeap: isLeap,
                actualLeapMonth: leap == 0 ? nil : leap
            )
        }

        if isLeap {
            return leap
        }
        if leap > 0, month > leap {
            return month
        }
        return month - 1
    }

    private func validateSequentialIndex(_ index: Int) throws {
        guard (0..<monthCount).contains(index) else {
            throw LunarYearRecordError.invalidSequentialIndex(
                index,
                monthCount: monthCount
            )
        }
    }
}
