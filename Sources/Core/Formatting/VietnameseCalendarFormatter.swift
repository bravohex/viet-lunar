import Foundation

public enum VietnameseCalendarFormatter: Sendable {
    public static func menuBarPresentation(
        for snapshot: CalendarSnapshot,
        format: MenuBarTitleFormat,
        clockText: String? = nil
    ) -> MenuBarTitlePresentation {
        let lunar = compactLunarDate(snapshot.lunarDate, includesSuffix: false)
        let solar = compactSolarDate(snapshot.solarDate)
        let title: String?

        switch format {
        case .lunarDate:
            title = compactMenuTitle(for: snapshot.lunarDate)
        case .solarAndLunar:
            title = "\(solar) · \(compactMenuTitle(for: snapshot.lunarDate))"
        case .lunarAndDayCanChi:
            title = "\(lunar) · \(canChi(snapshot.dayCanChi))"
        case .solarLunarAndDayCanChi:
            title = "\(solar) · \(lunar) · \(canChi(snapshot.dayCanChi))"
        case .iconOnly:
            title = nil
        }

        let composedTitle = [title, clockText]
            .compactMap { $0 }
            .joined(separator: " · ")
        let clockAccessibility = clockText.map { "; Giờ hệ thống \($0)" } ?? ""

        return MenuBarTitlePresentation(
            title: composedTitle.isEmpty ? nil : composedTitle,
            accessibilityLabel: "\(menuBarAccessibilityLabel(for: snapshot).dropLast())\(clockAccessibility)."
        )
    }

    public static func systemClockText(
        at instant: Date,
        timeZone: TimeZone,
        uses24HourClock: Bool
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "vi_VN")
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: instant)
        guard let hour = components.hour, let minute = components.minute else {
            preconditionFailure("Foundation produced invalid clock components")
        }

        if uses24HourClock {
            return "\(twoDigits(hour)):\(twoDigits(minute))"
        }

        let twelveHour = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "SA" : "CH"
        return "\(twelveHour):\(twoDigits(minute)) \(period)"
    }

    public static func compactMenuTitle(for lunarDate: LunarDate) -> String {
        compactLunarDate(lunarDate, includesSuffix: true)
    }

    public static func compactSolarDate(_ solarDate: SolarDate) -> String {
        "\(twoDigits(solarDate.day))/\(twoDigits(solarDate.month))"
    }

    public static func fullGregorianDate(_ solarDate: SolarDate) -> String {
        "\(weekdayName(for: solarDate)), \(solarDate.day) tháng \(solarDate.month) năm \(solarDate.year)"
    }

    public static func fullLunarDate(
        _ lunarDate: LunarDate,
        yearCanChi: StemBranch
    ) -> String {
        "Ngày \(lunarDateFragment(lunarDate)), năm \(canChi(yearCanChi))"
    }

    public static func popoverLunarDate(
        _ lunarDate: LunarDate,
        yearCanChi: StemBranch
    ) -> String {
        let leapMarker = lunarDate.isLeapMonth ? " nhuận" : ""
        return "\(twoDigits(lunarDate.day)) tháng \(lunarDate.month)\(leapMarker) năm \(canChi(yearCanChi))"
    }

    public static func monthTitle(_ yearMonth: YearMonth) -> String {
        "Tháng \(yearMonth.month) năm \(yearMonth.year)"
    }

    public static func canChi(_ value: StemBranch) -> String {
        value.description
    }

    public static func monthGridLunarLabel(_ lunarDate: LunarDate) -> String {
        guard lunarDate.day == 1 else {
            return String(lunarDate.day)
        }

        let leapMarker = lunarDate.isLeapMonth ? "N" : ""
        return "1/\(lunarDate.month)\(leapMarker)"
    }

    public static func cellAccessibilityLabel(
        for cell: MonthGridCell,
        yearCanChi: StemBranch
    ) -> String {
        let gregorian = "\(weekdayName(for: cell.solarDate)), ngày \(cell.solarDate.day) tháng \(cell.solarDate.month) năm \(cell.solarDate.year)"
        let lunar = "ngày \(lunarDateFragment(cell.lunarDate)), năm \(canChi(yearCanChi))"
        let today = cell.isToday ? "; hôm nay" : ""
        return "\(gregorian); \(lunar)\(today)."
    }

    public static func menuBarAccessibilityLabel(for snapshot: CalendarSnapshot) -> String {
        let gregorian = "\(weekdayName(for: snapshot.solarDate)), ngày \(snapshot.solarDate.day) tháng \(snapshot.solarDate.month) năm \(snapshot.solarDate.year)"
        let lunar = "ngày \(lunarDateFragment(snapshot.lunarDate)), năm \(canChi(snapshot.yearCanChi))"
        return "VietLunar; \(gregorian); \(lunar); Can–Chi ngày \(canChi(snapshot.dayCanChi)); Can–Chi giờ \(canChi(snapshot.hourCanChi))."
    }

    public static func weekdayName(for solarDate: SolarDate) -> String {
        switch floorMod(GregorianJDN.jdn(for: solarDate), 7) {
        case 0: "Thứ Hai"
        case 1: "Thứ Ba"
        case 2: "Thứ Tư"
        case 3: "Thứ Năm"
        case 4: "Thứ Sáu"
        case 5: "Thứ Bảy"
        case 6: "Chủ Nhật"
        default: preconditionFailure("floorMod must return a normalized weekday")
        }
    }

    private static func lunarDateFragment(_ lunarDate: LunarDate) -> String {
        let leapMarker = lunarDate.isLeapMonth ? " nhuận" : ""
        return "\(lunarDate.day) tháng \(lunarDate.month)\(leapMarker) âm lịch"
    }

    private static func compactLunarDate(
        _ lunarDate: LunarDate,
        includesSuffix: Bool
    ) -> String {
        let leapMarker = lunarDate.isLeapMonth ? "N" : ""
        let suffix = includesSuffix ? " ÂL" : ""
        return "\(twoDigits(lunarDate.day))/\(twoDigits(lunarDate.month))\(leapMarker)\(suffix)"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : String(value)
    }
}
