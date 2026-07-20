public enum VietnameseCalendarFormatter: Sendable {
    public static func compactMenuTitle(for lunarDate: LunarDate) -> String {
        let leapMarker = lunarDate.isLeapMonth ? "N" : ""
        return "\(twoDigits(lunarDate.day))/\(twoDigits(lunarDate.month))\(leapMarker) ÂL"
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

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : String(value)
    }
}
