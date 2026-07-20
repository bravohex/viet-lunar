import Foundation

@main
enum BenchmarkMain {
    static func main() throws {
        let engine = LunarCalendarEngine()
        let coldDate = try SolarDate(validatingYear: 2026, month: 7, day: 20)

        let coldStart = DispatchTime.now().uptimeNanoseconds
        _ = try engine.lunarDate(for: coldDate)
        let coldDuration = DispatchTime.now().uptimeNanoseconds - coldStart

        let lowerJDN = GregorianJDN.jdn(for: engine.supportedSolarRange.lowerBound)
        let upperJDN = GregorianJDN.jdn(for: engine.supportedSolarRange.upperBound)
        var conversionSamples: [UInt64] = []
        conversionSamples.reserveCapacity(upperJDN - lowerJDN + 1)
        var checksum = 0

        let conversionStart = DispatchTime.now().uptimeNanoseconds
        for jdn in lowerJDN...upperJDN {
            let solarDate = try GregorianJDN.solarDate(forJDN: jdn)
            let sampleStart = DispatchTime.now().uptimeNanoseconds
            let lunarDate = try engine.lunarDate(for: solarDate)
            conversionSamples.append(
                DispatchTime.now().uptimeNanoseconds - sampleStart
            )
            checksum &+= lunarDate.year
            checksum &+= lunarDate.month
            checksum &+= lunarDate.day
            checksum &+= lunarDate.isLeapMonth ? 1 : 0
        }
        let conversionDuration = DispatchTime.now().uptimeNanoseconds - conversionStart

        let roundTripStart = DispatchTime.now().uptimeNanoseconds
        for jdn in lowerJDN...upperJDN {
            let solarDate = try GregorianJDN.solarDate(forJDN: jdn)
            let lunarDate = try engine.lunarDate(for: solarDate)
            let recovered = try engine.solarDate(for: lunarDate)
            checksum &+= recovered.day
        }
        let roundTripDuration = DispatchTime.now().uptimeNanoseconds - roundTripStart

        let gridBuilder = MonthGridBuilder(lunarEngine: engine)
        let today = try SolarDate(validatingYear: 2026, month: 7, day: 20)
        var gridSamples: [UInt64] = []
        gridSamples.reserveCapacity(1_000)
        for index in 0..<1_000 {
            let month = (index % 12) + 1
            let year = 1900 + ((index / 12) % 200)
            let displayedMonth = try YearMonth(
                validatingYear: year,
                month: month
            )
            let sampleStart = DispatchTime.now().uptimeNanoseconds
            let cells = try gridBuilder.build(
                displayedMonth: displayedMonth,
                weekStart: index.isMultiple(of: 2) ? .monday : .sunday,
                today: today
            )
            gridSamples.append(
                DispatchTime.now().uptimeNanoseconds - sampleStart
            )
            checksum &+= cells.count
        }

        let snapshot = try CalendarSnapshotFactory(
            lunarEngine: engine,
            clock: FixedClock(
                instant: ISO8601DateFormatter().date(
                    from: "2026-07-20T05:00:00Z"
                ) ?? Date(timeIntervalSince1970: 0)
            )
        ).makeSnapshot()
        let formattingStart = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<10_000 {
            let presentation = VietnameseCalendarFormatter.menuBarPresentation(
                for: snapshot,
                format: .solarLunarAndDayCanChi,
                clockText: "12:00"
            )
            checksum &+= presentation.title?.utf8.count ?? 0
        }
        let formattingDuration = DispatchTime.now().uptimeNanoseconds - formattingStart

        print("cold_conversion_ms=\(milliseconds(coldDuration))")
        print("solar_to_lunar_count=\(conversionSamples.count)")
        print("solar_to_lunar_total_ms=\(milliseconds(conversionDuration))")
        print("solar_to_lunar_p95_ms=\(milliseconds(percentile95(conversionSamples)))")
        print("solar_lunar_round_trip_total_ms=\(milliseconds(roundTripDuration))")
        print("month_grid_count=\(gridSamples.count)")
        print("month_grid_p95_ms=\(milliseconds(percentile95(gridSamples)))")
        print("menu_format_10000_total_ms=\(milliseconds(formattingDuration))")
        print("checksum=\(checksum)")
    }

    private static func percentile95(_ samples: [UInt64]) -> UInt64 {
        let sorted = samples.sorted()
        let index = Int(Double(sorted.count - 1) * 0.95)
        return sorted[index]
    }

    private static func milliseconds(_ nanoseconds: UInt64) -> String {
        String(format: "%.6f", Double(nanoseconds) / 1_000_000)
    }
}
