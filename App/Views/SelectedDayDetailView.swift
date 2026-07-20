import SwiftUI
import VietLunarCore

struct SelectedDayDetailView: View {
    let cell: MonthGridCell
    let currentSnapshot: CalendarSnapshot

    private let calculator = CanChiCalculator()

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(VietnameseCalendarFormatter.fullGregorianDate(cell.solarDate))
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("selected-gregorian-date")
            Text(
                VietnameseCalendarFormatter.fullLunarDate(
                    cell.lunarDate,
                    yearCanChi: yearCanChi
                )
            )
            .font(.caption)
            .accessibilityIdentifier("selected-lunar-date")

            Text(
                verbatim: "Năm \(yearCanChi.description) · Tháng \(monthCanChi.description) · Ngày \(dayCanChi.description)"
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("selected-can-chi")

            if cell.solarDate == currentSnapshot.solarDate {
                Text(verbatim: "Giờ \(currentSnapshot.hourCanChi.description)")
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

}
