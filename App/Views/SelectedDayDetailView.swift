import SwiftUI
import VietLunarCore

struct SelectedDayDetailView: View {
    let cell: MonthGridCell
    let currentSnapshot: CalendarSnapshot

    private let calculator = CanChiCalculator()

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(VietnameseCalendarFormatter.fullGregorianDate(cell.solarDate))
                .font(.headline)
                .accessibilityIdentifier("selected-gregorian-date")
            Text(
                VietnameseCalendarFormatter.fullLunarDate(
                    cell.lunarDate,
                    yearCanChi: yearCanChi
                )
            )
            .font(.subheadline)
            .accessibilityIdentifier("selected-lunar-date")

            Text(
                AppLocalization.format(
                    "selected.can_chi",
                    fallback: "Năm %1$@ · Tháng %2$@ · Ngày %3$@",
                    yearCanChi.description,
                    monthCanChi.description,
                    dayCanChi.description
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("selected-can-chi")

            TraditionalDayStatusLabel(
                lunarDate: cell.lunarDate,
                solarDate: cell.solarDate,
                accessibilityIdentifier: "selected-day-classification"
            )

            Text(
                AppLocalization.format(
                    "selected.auspicious_hours",
                    fallback: "Giờ hoàng đạo: %@",
                    auspiciousHoursText
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(
                    AppLocalization.text(
                        "selected.auspicious_hours.title",
                        fallback: "Giờ hoàng đạo"
                    )
                )
                .accessibilityValue(auspiciousHoursText)
                .accessibilityIdentifier("selected-auspicious-hours")

            if cell.solarDate == currentSnapshot.solarDate {
                Text(
                    AppLocalization.format(
                        "selected.can_chi.hour",
                        fallback: "Giờ %@",
                        currentSnapshot.hourCanChi.description
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("selected-hour-can-chi")
            }
        }
    }

    private var yearCanChi: StemBranch {
        calculator.year(forLunarYear: cell.lunarDate.year)
    }

    private var monthCanChi: StemBranch {
        calculator.month(for: cell.lunarDate)
    }

    private var dayCanChi: StemBranch {
        calculator.day(for: cell.solarDate)
    }

    private var auspiciousHoursText: String {
        AuspiciousHourCalculator.hours(for: dayCanChi.branch)
            .map(\.description)
            .joined(separator: " · ")
    }

}
