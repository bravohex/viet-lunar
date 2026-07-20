import Foundation

enum AppLocalization {
    private static let vietnameseLocale = Locale(identifier: "vi")

    private static let bundle: Bundle = {
        guard let url = Bundle.main.url(
            forResource: "vi",
            withExtension: "lproj"
        ), let localizedBundle = Bundle(url: url) else {
            return .main
        }
        return localizedBundle
    }()

    static func text(_ key: String, fallback: String) -> String {
        bundle.localizedString(forKey: key, value: fallback, table: nil)
    }

    static func format(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: text(key, fallback: fallback),
            locale: vietnameseLocale,
            arguments: arguments
        )
    }
}
