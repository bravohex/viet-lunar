public struct LunarCalendarEngine: LunarCalendarCalculating {
    public static let productionSolarRange: ClosedRange<SolarDate> = {
        guard let lower = SolarDate.valid(year: 1800, month: 1, day: 1),
              let upper = SolarDate.valid(year: 2199, month: 12, day: 31)
        else {
            preconditionFailure("The production solar range must be valid")
        }
        return lower...upper
    }()

    public var supportedSolarRange: ClosedRange<SolarDate> {
        Self.productionSolarRange
    }

    public init() {}

    public func lunarDate(for solarDate: SolarDate) throws -> LunarDate {
        guard supportedSolarRange.contains(solarDate) else {
            throw LunarCalendarError.unsupportedSolarDate(solarDate)
        }

        let targetJDN = GregorianJDN.jdn(for: solarDate)
        let record = try record(containingJDN: targetJDN)
        var remainingDays = targetJDN - Int(record.tetJDN)

        for sequentialIndex in 0..<record.monthCount {
            let length = try decodedMonthLength(record, at: sequentialIndex)
            if remainingDays < length {
                let logical = try decodedLogicalMonth(record, at: sequentialIndex)
                guard let lunarDate = LunarDate.valid(
                    year: record.year,
                    month: logical.month,
                    day: remainingDays + 1,
                    isLeapMonth: logical.isLeap
                ) else {
                    throw LunarCalendarError.corruptedTable(
                        year: record.year,
                        reason: "Decoded lunar components are invalid"
                    )
                }
                return lunarDate
            }
            remainingDays -= length
        }

        throw LunarCalendarError.corruptedTable(
            year: record.year,
            reason: "JDN offset exceeds encoded lunar-year length"
        )
    }

    public func solarDate(for lunarDate: LunarDate) throws -> SolarDate {
        let record = try record(forLunarYear: lunarDate.year)
        let sequentialIndex: Int
        do {
            sequentialIndex = try record.sequentialIndex(
                month: lunarDate.month,
                isLeap: lunarDate.isLeapMonth
            )
        } catch LunarYearRecordError.invalidLogicalMonth {
            throw LunarCalendarError.invalidLeapMonth(
                requested: lunarDate.month,
                actual: record.leapMonth == 0 ? nil : Int(record.leapMonth)
            )
        } catch {
            throw LunarCalendarError.corruptedTable(
                year: record.year,
                reason: "Unable to map logical month: \(error)"
            )
        }

        let length = try decodedMonthLength(record, at: sequentialIndex)
        guard lunarDate.day <= length else {
            throw LunarCalendarError.dayExceedsMonthLength(
                day: lunarDate.day,
                length: length
            )
        }

        var offset = lunarDate.day - 1
        if sequentialIndex > 0 {
            for index in 0..<sequentialIndex {
                offset += try decodedMonthLength(record, at: index)
            }
        }

        let solarDate: SolarDate
        do {
            solarDate = try GregorianJDN.solarDate(
                forJDN: Int(record.tetJDN) + offset
            )
        } catch {
            throw LunarCalendarError.corruptedTable(
                year: record.year,
                reason: "Decoded JDN is invalid: \(error)"
            )
        }

        guard supportedSolarRange.contains(solarDate) else {
            throw LunarCalendarError.unsupportedSolarDate(solarDate)
        }
        return solarDate
    }

    public func monthLength(
        year: Int,
        month: Int,
        isLeapMonth: Bool
    ) throws -> Int {
        let record = try record(forLunarYear: year)
        let sequentialIndex: Int
        do {
            sequentialIndex = try record.sequentialIndex(
                month: month,
                isLeap: isLeapMonth
            )
        } catch LunarYearRecordError.invalidLogicalMonth {
            throw LunarCalendarError.invalidLeapMonth(
                requested: month,
                actual: record.leapMonth == 0 ? nil : Int(record.leapMonth)
            )
        }
        return try decodedMonthLength(record, at: sequentialIndex)
    }

    public func leapMonth(inLunarYear year: Int) throws -> Int? {
        let leapMonth = try record(forLunarYear: year).leapMonth
        return leapMonth == 0 ? nil : Int(leapMonth)
    }

    private func record(containingJDN targetJDN: Int) throws -> EncodedLunarYearRecord {
        let records = GeneratedLunarYearTableData.records
        var lowerBound = 0
        var upperBound = records.count

        while lowerBound < upperBound {
            let midpoint = lowerBound + ((upperBound - lowerBound) / 2)
            if Int(records[midpoint].tetJDN) <= targetJDN {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }

        let recordIndex = lowerBound - 1
        guard records.indices.contains(recordIndex) else {
            throw LunarCalendarError.corruptedTable(
                year: 0,
                reason: "No sentinel record precedes JDN \(targetJDN)"
            )
        }
        return records[recordIndex]
    }

    private func record(forLunarYear year: Int) throws -> EncodedLunarYearRecord {
        let index = year - GeneratedLunarYearTableData.firstYear
        guard GeneratedLunarYearTableData.records.indices.contains(index) else {
            throw LunarCalendarError.unsupportedLunarYear(year)
        }

        let record = GeneratedLunarYearTableData.records[index]
        guard record.year == year else {
            throw LunarCalendarError.corruptedTable(
                year: year,
                reason: "Generated record index does not match its lunar year"
            )
        }
        return record
    }

    private func decodedMonthLength(
        _ record: EncodedLunarYearRecord,
        at index: Int
    ) throws -> Int {
        do {
            return try record.monthLength(atSequentialIndex: index)
        } catch {
            throw LunarCalendarError.corruptedTable(
                year: record.year,
                reason: "Unable to decode month length at index \(index): \(error)"
            )
        }
    }

    private func decodedLogicalMonth(
        _ record: EncodedLunarYearRecord,
        at index: Int
    ) throws -> (month: Int, isLeap: Bool) {
        do {
            return try record.logicalMonth(atSequentialIndex: index)
        } catch {
            throw LunarCalendarError.corruptedTable(
                year: record.year,
                reason: "Unable to decode logical month at index \(index): \(error)"
            )
        }
    }
}
