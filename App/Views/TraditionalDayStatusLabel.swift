import SwiftUI
import VietLunarCore

/// Displays the compact traditional status when it is meaningful in context.
/// Ordinary days intentionally remain unlabelled in the header and detail area.
struct TraditionalDayStatusLabel: View {
    let lunarDate: LunarDate
    let solarDate: SolarDate
    let accessibilityIdentifier: String

    var body: some View {
        if let presentation {
            HStack(spacing: 5) {
                // Same dot as the month grid; the text carries the meaning.
                Circle()
                    .fill(presentation.color)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
                Text(presentation.text)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityLabel(presentation.text)
                    .accessibilityValue(presentation.text)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }
        }
    }

    private var presentation: (text: String, color: Color)? {
        switch TraditionalDayClassifier.classification(
            for: lunarDate,
            solarDate: solarDate
        ) {
        case .auspicious:
            (
                AppLocalization.text(
                    "day_classification.auspicious",
                    fallback: "Ngày hoàng đạo"
                ),
                .green
            )
        case .inauspicious:
            (
                AppLocalization.text(
                    "day_classification.inauspicious",
                    fallback: "Ngày hắc đạo"
                ),
                .gray
            )
        case .ordinary:
            nil
        }
    }
}
