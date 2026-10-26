import Foundation

private struct GeneratorError: Error, CustomStringConvertible {
    let description: String
}

private struct CivilDate: Equatable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    var iso8601: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

private struct LunarValue: Equatable {
    let year: Int
    let month: Int
    let day: Int
    let isLeapMonth: Bool
}

private struct MonthStart {
    let month: Int
    let isLeapMonth: Bool
    let startJDN: Int
}

private struct YearRecord {
    let year: Int
    let tetJDN: Int
    let leapMonth: Int
    let monthLengths: [Int]

    var monthLengthBits: UInt16 {
        monthLengths.enumerated().reduce(into: UInt16(0)) { result, pair in
            if pair.element == 30 {
                result |= UInt16(1) << UInt16(pair.offset)
            }
        }
    }
}

private struct ReferencePayload: Codable {
    let schemaVersion: Int
    let calendar: String
    let calculationTimeZone: String
    let generator: String
    let independence: String
    let lowerSolarDate: String
    let upperSolarDate: String
    let lowerSolarJDN: Int
    let upperSolarJDN: Int
    let columns: [String]
    let rows: [[Int]]
}

private struct Arguments {
    let lowerDate: CivilDate
    let upperDate: CivilDate
    let timeZoneHours: Double
    let swiftOutput: URL
    let referenceOutput: URL

    init(commandLine: [String]) throws {
        var values: [String: String] = [:]
        var index = 1
        while index < commandLine.count {
            let key = commandLine[index]
            guard key.hasPrefix("--"), index + 1 < commandLine.count else {
                throw GeneratorError(description: "Invalid argument near \(key)")
            }
            values[key] = commandLine[index + 1]
            index += 2
        }

        guard let rangeValue = values["--range"],
              let separator = rangeValue.range(of: "...")
        else {
            throw GeneratorError(description: "Missing --range YYYY-MM-DD...YYYY-MM-DD")
        }

        lowerDate = try Self.parseDate(String(rangeValue[..<separator.lowerBound]))
        upperDate = try Self.parseDate(String(rangeValue[separator.upperBound...]))
        guard lowerDate <= upperDate else {
            throw GeneratorError(description: "The lower date must not follow the upper date")
        }

        guard values["--timezone"] == "+07:00" else {
            throw GeneratorError(description: "VietLunar generation requires --timezone +07:00")
        }
        timeZoneHours = 7.0

        guard let swiftPath = values["--swift-output"],
              let referencePath = values["--reference-output"]
        else {
            throw GeneratorError(
                description: "Both --swift-output and --reference-output are required"
            )
        }

        swiftOutput = URL(fileURLWithPath: swiftPath)
        referenceOutput = URL(fileURLWithPath: referencePath)
    }

    private static func parseDate(_ value: String) throws -> CivilDate {
        let components = value.split(separator: "-")
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]),
              (1...12).contains(month),
              (1...31).contains(day)
        else {
            throw GeneratorError(description: "Invalid Gregorian date: \(value)")
        }
        return CivilDate(year: year, month: month, day: day)
    }
}

private enum Astronomy {
    static func gregorianJDN(_ date: CivilDate) -> Int {
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

    static func civilDate(forJDN jdn: Int) -> CivilDate {
        let shifted = jdn + 32_044
        let century = (4 * shifted + 3) / 146_097
        let dayInCentury = shifted - ((146_097 * century) / 4)
        let yearInCentury = (4 * dayInCentury + 3) / 1_461
        let dayInYear = dayInCentury - ((1_461 * yearInCentury) / 4)
        let monthIndex = (5 * dayInYear + 2) / 153
        let day = dayInYear - ((153 * monthIndex + 2) / 5) + 1
        let month = monthIndex + 3 - (12 * (monthIndex / 10))
        let year = (100 * century) + yearInCentury - 4_800 + (monthIndex / 10)
        return CivilDate(year: year, month: month, day: day)
    }

    static func lunarDate(for solarDate: CivilDate, timeZoneHours: Double) -> LunarValue {
        let dayNumber = gregorianJDN(solarDate)
        var k = Int(floor((Double(dayNumber) - 2_415_021.076_998_695) / 29.530_588_853))
        var monthStart = newMoonDay(k: k, timeZoneHours: timeZoneHours)
        // The mean lunation estimate can lie on either side of the actual new moon.
        while monthStart > dayNumber {
            k -= 1
            monthStart = newMoonDay(k: k, timeZoneHours: timeZoneHours)
        }
        var nextStart = newMoonDay(k: k + 1, timeZoneHours: timeZoneHours)
        while nextStart <= dayNumber {
            k += 1
            monthStart = nextStart
            nextStart = newMoonDay(k: k + 1, timeZoneHours: timeZoneHours)
        }

        var month11Start = lunarMonth11(year: solarDate.year, timeZoneHours: timeZoneHours)
        var nextMonth11Start = month11Start
        var lunarYear: Int

        if month11Start >= monthStart {
            lunarYear = solarDate.year
            month11Start = lunarMonth11(
                year: solarDate.year - 1,
                timeZoneHours: timeZoneHours
            )
        } else {
            lunarYear = solarDate.year + 1
            nextMonth11Start = lunarMonth11(
                year: solarDate.year + 1,
                timeZoneHours: timeZoneHours
            )
        }

        let lunarDay = dayNumber - monthStart + 1
        let difference = Int(floor(Double(monthStart - month11Start) / 29.0))
        var lunarMonth = difference + 11
        var isLeapMonth = false

        if nextMonth11Start - month11Start > 365 {
            let leapOffset = leapMonthOffset(
                month11Start: month11Start,
                timeZoneHours: timeZoneHours
            )
            if difference >= leapOffset {
                lunarMonth = difference + 10
                isLeapMonth = difference == leapOffset
            }
        }

        if lunarMonth > 12 {
            lunarMonth -= 12
        }
        if lunarMonth >= 11, difference < 4 {
            lunarYear -= 1
        }

        return LunarValue(
            year: lunarYear,
            month: lunarMonth,
            day: lunarDay,
            isLeapMonth: isLeapMonth
        )
    }

    private static func newMoonDay(k: Int, timeZoneHours: Double) -> Int {
        let t = Double(k) / 1_236.85
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        let degreesToRadians = Double.pi / 180.0

        var julianDate = 2_415_020.759_33
            + (29.530_588_68 * Double(k))
            + (0.000_117_8 * t2)
            - (0.000_000_155 * t3)
        julianDate += 0.000_33 * sin(
            (166.56 + (132.87 * t) - (0.009_173 * t2)) * degreesToRadians
        )

        let sunAnomaly = (
            359.2242
                + (29.105_356_08 * Double(k))
                - (0.000_033_3 * t2)
                - (0.000_003_47 * t3)
        ) * degreesToRadians
        let moonAnomaly = (
            306.0253
                + (385.816_918_06 * Double(k))
                + (0.010_730_6 * t2)
                + (0.000_012_36 * t3)
                - (0.000_000_058 * t4)
        ) * degreesToRadians
        let latitudeArgument = (
            21.2964
                + (390.670_506_46 * Double(k))
                - (0.001_652_8 * t2)
                - (0.000_002_39 * t3)
                + (0.000_000_011 * t4)
        ) * degreesToRadians

        var correction = (0.1734 - (0.000_393 * t)) * sin(sunAnomaly)
        correction += 0.0021 * sin(2 * sunAnomaly)
        correction -= 0.4068 * sin(moonAnomaly)
        correction += 0.0161 * sin(2 * moonAnomaly)
        correction -= 0.0004 * sin(3 * moonAnomaly)
        correction += 0.0104 * sin(2 * latitudeArgument)
        correction -= 0.0051 * sin(sunAnomaly + moonAnomaly)
        correction -= 0.0074 * sin(sunAnomaly - moonAnomaly)
        correction += 0.0004 * sin((2 * latitudeArgument) + sunAnomaly)
        correction -= 0.0004 * sin((2 * latitudeArgument) - sunAnomaly)
        correction -= 0.0006 * sin((2 * latitudeArgument) + moonAnomaly)
        correction += 0.0010 * sin((2 * latitudeArgument) - moonAnomaly)
        correction += 0.0005 * sin((2 * moonAnomaly) + sunAnomaly)

        let deltaT: Double
        if t < -11 {
            deltaT = 0.001
                + (0.000_839 * t)
                + (0.000_226_1 * t2)
                - (0.000_008_45 * t3)
                - (0.000_000_081 * t4)
        } else {
            deltaT = -0.000_278 + (0.000_265 * t) + (0.000_262 * t2)
        }

        return Int(floor(julianDate + correction - deltaT + 0.5 + (timeZoneHours / 24.0)))
    }

    private static func sunLongitudeSegment(jdn: Int, timeZoneHours: Double) -> Int {
        let t = (
            Double(jdn)
                - 2_451_545.5
                - (timeZoneHours / 24.0)
        ) / 36_525.0
        let t2 = t * t
        let degreesToRadians = Double.pi / 180.0
        let meanAnomaly = (
            357.529_10
                + (35_999.050_30 * t)
                - (0.000_155_9 * t2)
                - (0.000_000_48 * t2 * t)
        ) * degreesToRadians
        let meanLongitude = (
            280.466_45
                + (36_000.769_83 * t)
                + (0.000_303_2 * t2)
        ) * degreesToRadians

        var correction = (
            1.914_600
                - (0.004_817 * t)
                - (0.000_014 * t2)
        ) * sin(meanAnomaly)
        correction += (0.019_993 - (0.000_101 * t)) * sin(2 * meanAnomaly)
        correction += 0.000_290 * sin(3 * meanAnomaly)

        var longitude = meanLongitude + (correction * degreesToRadians)
        longitude -= Double.pi * 2 * floor(longitude / (Double.pi * 2))
        return Int(floor((longitude / Double.pi) * 6.0))
    }

    private static func lunarMonth11(year: Int, timeZoneHours: Double) -> Int {
        let offset = gregorianJDN(CivilDate(year: year, month: 12, day: 31)) - 2_415_021
        let k = Int(floor(Double(offset) / 29.530_588_853))
        var newMoon = newMoonDay(k: k, timeZoneHours: timeZoneHours)
        if sunLongitudeSegment(jdn: newMoon, timeZoneHours: timeZoneHours) >= 9 {
            newMoon = newMoonDay(k: k - 1, timeZoneHours: timeZoneHours)
        }
        return newMoon
    }

    private static func leapMonthOffset(
        month11Start: Int,
        timeZoneHours: Double
    ) -> Int {
        let k = Int(round(
            (Double(month11Start) - 2_415_021.076_998_695) / 29.530_588_853
        ))
        var lastSegment = sunLongitudeSegment(
            jdn: newMoonDay(k: k + 1, timeZoneHours: timeZoneHours),
            timeZoneHours: timeZoneHours
        )
        var index = 2
        var segment = sunLongitudeSegment(
            jdn: newMoonDay(k: k + index, timeZoneHours: timeZoneHours),
            timeZoneHours: timeZoneHours
        )

        while segment != lastSegment, index < 14 {
            lastSegment = segment
            index += 1
            segment = sunLongitudeSegment(
                jdn: newMoonDay(k: k + index, timeZoneHours: timeZoneHours),
                timeZoneHours: timeZoneHours
            )
        }
        return index - 1
    }
}

private enum Generator {
    static func run(arguments: Arguments) throws {
        let lowerJDN = Astronomy.gregorianJDN(arguments.lowerDate)
        let upperJDN = Astronomy.gregorianJDN(arguments.upperDate)
        guard upperJDN - lowerJDN + 1 == 146_097 else {
            throw GeneratorError(description: "Expected exactly 146,097 production dates")
        }

        let records = try buildYearRecords(timeZoneHours: arguments.timeZoneHours)
        try validate(records: records, lowerJDN: lowerJDN, upperJDN: upperJDN)
        try validateCuratedSentinels(timeZoneHours: arguments.timeZoneHours)

        let swiftSource = renderSwift(records: records)
        let recordsByYear = Dictionary(uniqueKeysWithValues: records.map { ($0.year, $0) })

        var rows: [[Int]] = []
        rows.reserveCapacity(upperJDN - lowerJDN + 1)
        for jdn in lowerJDN...upperJDN {
            let solar = Astronomy.civilDate(forJDN: jdn)
            let lunar = Astronomy.lunarDate(
                for: solar,
                timeZoneHours: arguments.timeZoneHours
            )
            guard let record = recordsByYear[lunar.year], (1...12).contains(lunar.month),
                  !lunar.isLeapMonth || record.leapMonth == lunar.month else {
                throw GeneratorError(description: "Invalid reference month at \(solar.iso8601)")
            }
            let monthIndex = lunar.month - 1
                + ((record.leapMonth > 0 && lunar.month > record.leapMonth) ? 1 : 0)
                + (lunar.isLeapMonth ? 1 : 0)
            guard record.monthLengths.indices.contains(monthIndex),
                  (1...record.monthLengths[monthIndex]).contains(lunar.day),
                  record.tetJDN + record.monthLengths.prefix(monthIndex).reduce(0, +)
                    + lunar.day - 1 == jdn else {
                throw GeneratorError(description: "Reference/table mismatch at \(solar.iso8601)")
            }
            rows.append([
                jdn,
                lunar.year,
                lunar.month,
                lunar.day,
                lunar.isLeapMonth ? 1 : 0
            ])
        }

        let payload = ReferencePayload(
            schemaVersion: 1,
            calendar: "Vietnamese modern astronomical lunisolar calendar",
            calculationTimeZone: "+07:00",
            generator: "VietLunar original Swift astronomical table generator v2",
            independence: "Candidate data from the production-table generator; not an independent conformance oracle.",
            lowerSolarDate: arguments.lowerDate.iso8601,
            upperSolarDate: arguments.upperDate.iso8601,
            lowerSolarJDN: lowerJDN,
            upperSolarJDN: upperJDN,
            columns: [
                "solarJDN",
                "lunarYear",
                "lunarMonth",
                "lunarDay",
                "isLeapMonth"
            ],
            rows: rows
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var referenceData = try encoder.encode(payload)
        referenceData.append(0x0A)
        try write(Data(swiftSource.utf8), to: arguments.swiftOutput)
        try write(referenceData, to: arguments.referenceOutput)

        print("Generated \(records.count) lunar-year records (1799...2200)")
        print("Generated \(rows.count) reference rows (1800-01-01...2199-12-31)")
    }

    private static func buildYearRecords(timeZoneHours: Double) throws -> [YearRecord] {
        let scanLower = Astronomy.gregorianJDN(CivilDate(year: 1799, month: 1, day: 1))
        let scanUpper = Astronomy.gregorianJDN(CivilDate(year: 2201, month: 3, day: 31))
        var startsByYear: [Int: [MonthStart]] = [:]

        for jdn in scanLower...scanUpper {
            let solar = Astronomy.civilDate(forJDN: jdn)
            let lunar = Astronomy.lunarDate(for: solar, timeZoneHours: timeZoneHours)
            if lunar.day == 1 {
                startsByYear[lunar.year, default: []].append(
                    MonthStart(
                        month: lunar.month,
                        isLeapMonth: lunar.isLeapMonth,
                        startJDN: jdn
                    )
                )
            }
        }

        var records: [YearRecord] = []
        for year in 1799...2200 {
            guard let rawStarts = startsByYear[year] else {
                throw GeneratorError(description: "Missing lunar-year starts for \(year)")
            }
            let starts = rawStarts.sorted { $0.startJDN < $1.startJDN }
            guard let nextTet = startsByYear[year + 1]?
                .first(where: { $0.month == 1 && !$0.isLeapMonth })?
                .startJDN
            else {
                throw GeneratorError(description: "Missing next Tết sentinel for \(year)")
            }
            guard starts.count == 12 || starts.count == 13,
                  starts.first?.month == 1,
                  starts.first?.isLeapMonth == false
            else {
                throw GeneratorError(description: "Invalid month sequence for \(year)")
            }

            let leapStarts = starts.filter(\.isLeapMonth)
            guard leapStarts.count == (starts.count == 13 ? 1 : 0) else {
                throw GeneratorError(description: "Invalid leap-month count for \(year)")
            }

            var lengths: [Int] = []
            for index in starts.indices {
                let nextStart = index + 1 < starts.count
                    ? starts[index + 1].startJDN
                    : nextTet
                let length = nextStart - starts[index].startJDN
                guard length == 29 || length == 30 else {
                    throw GeneratorError(
                        description: "Invalid month length \(length) in lunar year \(year)"
                    )
                }
                lengths.append(length)
            }

            records.append(
                YearRecord(
                    year: year,
                    tetJDN: starts[0].startJDN,
                    leapMonth: leapStarts.first?.month ?? 0,
                    monthLengths: lengths
                )
            )
        }
        return records
    }

    private static func validate(records: [YearRecord], lowerJDN: Int, upperJDN: Int) throws {
        guard records.count == 402,
              records.first?.year == 1799,
              records.last?.year == 2200,
              let firstTet = records.first?.tetJDN,
              let lastTet = records.last?.tetJDN,
              firstTet <= lowerJDN,
              lastTet > upperJDN
        else {
            throw GeneratorError(description: "Sentinel coverage is incomplete")
        }

        for pair in zip(records, records.dropFirst()) {
            guard pair.0.tetJDN < pair.1.tetJDN,
                  pair.0.monthLengths.reduce(0, +) == pair.1.tetJDN - pair.0.tetJDN,
                  (pair.0.leapMonth == 0) == (pair.0.monthLengths.count == 12)
            else {
                throw GeneratorError(description: "Year invariant failed for \(pair.0.year)")
            }
        }
    }

    private static func validateCuratedSentinels(timeZoneHours: Double) throws {
        let sentinels: [(CivilDate, LunarValue)] = [
            (
                CivilDate(year: 1984, month: 2, day: 1),
                LunarValue(year: 1983, month: 12, day: 30, isLeapMonth: false)
            ),
            (
                CivilDate(year: 1984, month: 2, day: 2),
                LunarValue(year: 1984, month: 1, day: 1, isLeapMonth: false)
            ),
            (
                CivilDate(year: 2004, month: 3, day: 21),
                LunarValue(year: 2004, month: 2, day: 1, isLeapMonth: true)
            ),
            (
                CivilDate(year: 2025, month: 8, day: 18),
                LunarValue(year: 2025, month: 6, day: 25, isLeapMonth: true)
            ),
            (
                CivilDate(year: 2033, month: 12, day: 22),
                LunarValue(year: 2033, month: 11, day: 1, isLeapMonth: true)
            ),
            (
                CivilDate(year: 2034, month: 1, day: 20),
                LunarValue(year: 2033, month: 12, day: 1, isLeapMonth: false)
            )
        ]

        for sentinel in sentinels {
            let actual = Astronomy.lunarDate(
                for: sentinel.0,
                timeZoneHours: timeZoneHours
            )
            guard actual == sentinel.1 else {
                throw GeneratorError(
                    description: "Curated sentinel mismatch for \(sentinel.0.iso8601): \(actual)"
                )
            }
        }
    }

    private static func renderSwift(records: [YearRecord]) -> String {
        let rows = records.map { record in
            let bits = String(format: "0x%04X", record.monthLengthBits)
            return "        EncodedLunarYearRecord(uncheckedYear: \(record.year), tetJDN: \(record.tetJDN), leapMonth: \(record.leapMonth), monthLengthBits: \(bits))"
        }.joined(separator: ",\n")

        return """
        // Generated by Tools/CalendarTableGenerator/main.swift. Do not edit.
        // Convention: Vietnamese modern astronomical lunar calendar, UTC+7.
        // Coverage includes sentinel lunar years 1799...2200.

        enum GeneratedLunarYearTableData {
            static let firstYear = 1799
            static let lastYear = 2200
            static let records: [EncodedLunarYearRecord] = [
        \(rows)
            ]
        }

        """
    }

    private static func write(_ data: Data, to output: URL) throws {
        try FileManager.default.createDirectory(
            at: output.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: output, options: .atomic)
    }
}

do {
    let arguments = try Arguments(commandLine: CommandLine.arguments)
    try Generator.run(arguments: arguments)
} catch {
    FileHandle.standardError.write(Data("CalendarTableGenerator: \(error)\n".utf8))
    exit(1)
}
