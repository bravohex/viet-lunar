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
        let clockAccessibility = clockText.map {
            CoreLocalization.format(
                "menu_title.clock_accessibility",
                fallback: "; Giờ hệ thống %@",
                $0
            )
        } ?? ""

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
        let period = hour < 12
            ? CoreLocalization.text("clock.period.am", fallback: "SA")
            : CoreLocalization.text("clock.period.pm", fallback: "CH")
        return "\(twelveHour):\(twoDigits(minute)) \(period)"
    }

    public static func compactMenuTitle(for lunarDate: LunarDate) -> String {
        compactLunarDate(lunarDate, includesSuffix: true)
    }

    public static func compactSolarDate(_ solarDate: SolarDate) -> String {
        "\(twoDigits(solarDate.day))/\(twoDigits(solarDate.month))"
    }

    public static func fullGregorianDate(_ solarDate: SolarDate) -> String {
        CoreLocalization.format(
            "date.gregorian.full",
            fallback: "%1$@, %2$lld tháng %3$lld năm %4$lld",
            weekdayName(for: solarDate),
            Int64(solarDate.day),
            Int64(solarDate.month),
            Int64(solarDate.year)
        )
    }

    public static func fullLunarDate(
        _ lunarDate: LunarDate,
        yearCanChi: StemBranch
    ) -> String {
        CoreLocalization.format(
            "date.lunar.full",
            fallback: "Ngày %1$@, năm %2$@",
            lunarDateFragment(lunarDate),
            canChi(yearCanChi)
        )
    }

    public static func popoverLunarDate(
        _ lunarDate: LunarDate,
        yearCanChi: StemBranch
    ) -> String {
        if lunarDate.isLeapMonth {
            return CoreLocalization.format(
                "date.lunar.popover.leap",
                fallback: "%1$@ tháng %2$lld nhuận năm %3$@",
                twoDigits(lunarDate.day),
                Int64(lunarDate.month),
                canChi(yearCanChi)
            )
        }
        return CoreLocalization.format(
            "date.lunar.popover.normal",
            fallback: "%1$@ tháng %2$lld năm %3$@",
            twoDigits(lunarDate.day),
            Int64(lunarDate.month),
            canChi(yearCanChi)
        )
    }

    public static func monthTitle(_ yearMonth: YearMonth) -> String {
        CoreLocalization.format(
            "month.title",
            fallback: "Tháng %1$lld năm %2$lld",
            Int64(yearMonth.month),
            Int64(yearMonth.year)
        )
    }

    public static func canChi(_ value: StemBranch) -> String {
        value.description
    }

    public static func monthGridLunarLabel(_ lunarDate: LunarDate) -> String {
        guard lunarDate.day == 1 else {
            return String(lunarDate.day)
        }

        let leapMarker = lunarDate.isLeapMonth
            ? CoreLocalization.text("lunar.compact.leap_marker", fallback: "N")
            : ""
        return "1/\(lunarDate.month)\(leapMarker)"
    }

    public static func cellAccessibilityLabel(
        for cell: MonthGridCell,
        yearCanChi: StemBranch
    ) -> String {
        let gregorian = accessibilityGregorianDate(cell.solarDate)
        let lunar = CoreLocalization.format(
            "accessibility.lunar_date",
            fallback: "ngày %1$@, năm %2$@",
            lunarDateFragment(cell.lunarDate),
            canChi(yearCanChi)
        )
        let today = cell.isToday
            ? CoreLocalization.text(
                "accessibility.today_suffix",
                fallback: "; hôm nay"
            )
            : ""
        return "\(gregorian); \(lunar)\(today)."
    }

    public static func menuBarAccessibilityLabel(for snapshot: CalendarSnapshot) -> String {
        let gregorian = accessibilityGregorianDate(snapshot.solarDate)
        let lunar = CoreLocalization.format(
            "accessibility.lunar_date",
            fallback: "ngày %1$@, năm %2$@",
            lunarDateFragment(snapshot.lunarDate),
            canChi(snapshot.yearCanChi)
        )
        return CoreLocalization.format(
            "accessibility.menu_bar",
            fallback: "VietLunar; %1$@; %2$@; Can–Chi ngày %3$@; Can–Chi giờ %4$@.",
            gregorian,
            lunar,
            canChi(snapshot.dayCanChi),
            canChi(snapshot.hourCanChi)
        )
    }

    public static func weekdayName(for solarDate: SolarDate) -> String {
        switch floorMod(GregorianJDN.jdn(for: solarDate), 7) {
        case 0: CoreLocalization.text("weekday.monday", fallback: "Thứ Hai")
        case 1: CoreLocalization.text("weekday.tuesday", fallback: "Thứ Ba")
        case 2: CoreLocalization.text("weekday.wednesday", fallback: "Thứ Tư")
        case 3: CoreLocalization.text("weekday.thursday", fallback: "Thứ Năm")
        case 4: CoreLocalization.text("weekday.friday", fallback: "Thứ Sáu")
        case 5: CoreLocalization.text("weekday.saturday", fallback: "Thứ Bảy")
        case 6: CoreLocalization.text("weekday.sunday", fallback: "Chủ Nhật")
        default: preconditionFailure("floorMod must return a normalized weekday")
        }
    }

    private static func lunarDateFragment(_ lunarDate: LunarDate) -> String {
        if lunarDate.isLeapMonth {
            return CoreLocalization.format(
                "lunar.fragment.leap",
                fallback: "%1$lld tháng %2$lld nhuận âm lịch",
                Int64(lunarDate.day),
                Int64(lunarDate.month)
            )
        }
        return CoreLocalization.format(
            "lunar.fragment.normal",
            fallback: "%1$lld tháng %2$lld âm lịch",
            Int64(lunarDate.day),
            Int64(lunarDate.month)
        )
    }

    private static func compactLunarDate(
        _ lunarDate: LunarDate,
        includesSuffix: Bool
    ) -> String {
        let leapMarker = lunarDate.isLeapMonth
            ? CoreLocalization.text("lunar.compact.leap_marker", fallback: "N")
            : ""
        let suffix = includesSuffix
            ? CoreLocalization.text("lunar.compact.suffix", fallback: " ÂL")
            : ""
        return "\(twoDigits(lunarDate.day))/\(twoDigits(lunarDate.month))\(leapMarker)\(suffix)"
    }

    private static func accessibilityGregorianDate(_ solarDate: SolarDate) -> String {
        CoreLocalization.format(
            "accessibility.gregorian_date",
            fallback: "%1$@, ngày %2$lld tháng %3$lld năm %4$lld",
            weekdayName(for: solarDate),
            Int64(solarDate.day),
            Int64(solarDate.month),
            Int64(solarDate.year)
        )
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : String(value)
    }
}
