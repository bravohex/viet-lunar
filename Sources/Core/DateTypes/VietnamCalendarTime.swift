import Foundation

public enum VietnamCalendarConvention: Sendable {
    public static let timeZoneOffsetSeconds = 7 * 60 * 60
    public static let timeZoneHours = 7.0
}

public enum VietnamCalendarTime: Sendable {
    public static let timeZone: TimeZone = {
        guard let timeZone = TimeZone(
            secondsFromGMT: VietnamCalendarConvention.timeZoneOffsetSeconds
        ) else {
            preconditionFailure("UTC+7 must be a valid fixed time zone")
        }
        return timeZone
    }()

    public static func solarDate(containing instant: Date) -> SolarDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "vi_VN")

        let components = calendar.dateComponents([.year, .month, .day], from: instant)
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let solarDate = SolarDate.valid(year: year, month: month, day: day)
        else {
            preconditionFailure("Foundation produced invalid Gregorian components")
        }

        return solarDate
    }
}
