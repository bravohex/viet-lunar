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
                VietnameseCalendarFormatter.popoverLunarDate(
                    snapshot.lunarDate,
                    yearCanChi: snapshot.yearCanChi
                )
            )
            .foregroundStyle(.secondary)

            Text(
                verbatim: "Ngày \(snapshot.dayCanChi.description) · Tháng \(snapshot.monthCanChi.description)"
            )
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(verbatim: "Giờ \(snapshot.hourCanChi.description)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
