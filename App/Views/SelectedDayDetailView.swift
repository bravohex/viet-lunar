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
            Text(
                VietnameseCalendarFormatter.fullLunarDate(
                    cell.lunarDate,
                    yearCanChi: yearCanChi
                )
            )
            .font(.caption)

            Text(
                verbatim: "Năm \(yearCanChi.description) · Tháng \(monthCanChi.description) · Ngày \(dayCanChi.description)"
            )
                .font(.caption)
                .foregroundStyle(.secondary)

            if cell.solarDate == currentSnapshot.solarDate {
                Text(verbatim: "Giờ \(currentSnapshot.hourCanChi.description)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(detailAccessibilityLabel)
        .accessibilityIdentifier("selected-day-detail")
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

    private var detailAccessibilityLabel: String {
        var parts = [
            VietnameseCalendarFormatter.cellAccessibilityLabel(
                for: cell,
                yearCanChi: yearCanChi
            ),
            "Can–Chi tháng \(monthCanChi.description)",
            "Can–Chi ngày \(dayCanChi.description)"
        ]
        if cell.solarDate == currentSnapshot.solarDate {
            parts.append("Can–Chi giờ \(currentSnapshot.hourCanChi.description)")
        }
        return parts.joined(separator: "; ")
    }
}
