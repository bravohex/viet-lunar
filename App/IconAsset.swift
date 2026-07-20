import AppKit
import SwiftUI

enum IconAsset: String, Sendable {
    case menuBarLunar = "VLMenuBarLunar"
    case previous = "VLPrevious"
    case next = "VLNext"
    case today = "VLToday"
    case settings = "VLSettings"
    case info = "VLInfo"
    case quit = "VLQuit"

    var image: Image {
        Image(rawValue)
            .renderingMode(.template)
    }

    @MainActor
    var nsImage: NSImage? {
        let image = NSImage(named: NSImage.Name(rawValue))
        image?.isTemplate = true
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
    }
}
