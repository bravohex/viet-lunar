import AppKit
import SwiftUI

enum IconAsset: String, Sendable {
    case menuBarLunar = "LucideCalendarDays"
    case previous = "LucideChevronLeft"
    case next = "LucideChevronRight"
    case today = "LucideCalendarCheck"
    case settings = "LucideSettings"
    case info = "LucideInfo"
    case quit = "LucidePower"
    case holiday = "LucideFlag"
    case observance = "LucideBookmark"
    case warning = "LucideTriangleAlert"

    var image: Image {
        Image(rawValue)
            .renderingMode(.template)
    }

    @MainActor
    var nsImage: NSImage? {
        let image = NSImage(named: NSImage.Name(rawValue))
        image?.isTemplate = true
        if self == .menuBarLunar {
            image?.size = NSSize(width: 18, height: 18)
        }
        return image
    }
}

struct AssetIconView: View {
    private let asset: IconAsset
    private let size: CGFloat

    init(_ asset: IconAsset, size: CGFloat = 18) {
        self.asset = asset
        self.size = size
    }

    var body: some View {
        asset.image
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
