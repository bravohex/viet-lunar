import SwiftUI
import VietLunarCore

/// Holidays use a flag, observances a bookmark, so kind is not color-only.
struct HolidayStatusLabel: View {
    let holidays: [HolidayOccurrence]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(holidays.enumerated()), id: \.offset) { index, holiday in
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    AssetIconView(holiday.kind == .official ? .holiday : .observance, size: 14)
                        .foregroundStyle(holiday.kind == .official ? Color.red : Color.secondary)
                        .accessibilityHidden(true)
                    Text(holiday.displayName)
                        .foregroundStyle(holiday.kind == .official ? Color.primary : Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("selected-holiday-\(index)")
                }
                .font(.subheadline)
            }
        }
    }
}

extension HolidayOccurrence {
    /// The name, followed by the position inside a multi-day holiday.
    var displayName: String {
        guard dayCount > 1 else {
            return name
        }
        return AppLocalization.format(
            "holidays.multi_day",
            fallback: "%1$@ (ngày %2$ld/%3$ld)",
            name,
            dayNumber,
            dayCount
        )
    }
}
