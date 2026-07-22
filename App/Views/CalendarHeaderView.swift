import SwiftUI
import VietLunarCore

struct CalendarHeaderView: View {
    let snapshot: CalendarSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(VietnameseCalendarFormatter.fullGregorianDate(snapshot.solarDate))
                .font(.headline)
                .accessibilityIdentifier("today-header")

            Text(
                VietnameseCalendarFormatter.fullLunarDate(
                    snapshot.lunarDate,
                    yearCanChi: snapshot.yearCanChi
                )
            )
            .foregroundStyle(.secondary)

            TraditionalDayStatusLabel(
                lunarDate: snapshot.lunarDate,
                solarDate: snapshot.solarDate,
                accessibilityIdentifier: "today-day-classification"
            )

            Text(
                AppLocalization.format(
                    "header.can_chi.day_month",
                    fallback: "Ngày %1$@ · Tháng %2$@",
                    snapshot.dayCanChi.description,
                    snapshot.monthCanChi.description
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                AppLocalization.format(
                    "header.can_chi.hour",
                    fallback: "Giờ %@",
                    snapshot.hourCanChi.description
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                AppLocalization.text(
                    "header.canonical_time_zone",
                    fallback: "Lịch Việt Nam: UTC+7"
                )
            )
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .accessibilityIdentifier("canonical-time-zone-note")
        }
    }
}
