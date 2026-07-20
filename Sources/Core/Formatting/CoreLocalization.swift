import Foundation

private final class CoreBundleToken: NSObject {}

enum CoreLocalization {
    private static let formatLocale = Locale(identifier: "en_US_POSIX")

    private static let bundle: Bundle = {
        let frameworkBundle = Bundle(for: CoreBundleToken.self)
        guard let url = frameworkBundle.url(
            forResource: "vi",
            withExtension: "lproj"
        ), let localizedBundle = Bundle(url: url) else {
            return frameworkBundle
        }
        return localizedBundle
    }()

    static var hasVietnameseCatalog: Bool {
        bundle.url(forResource: "Localizable", withExtension: "strings") != nil
    }

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
            locale: formatLocale,
            arguments: arguments
        )
    }
}
