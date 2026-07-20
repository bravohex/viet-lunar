import Foundation

/// The ten heavenly stems in their canonical cycle order.
public enum HeavenlyStem: Int, CaseIterable, Codable, Sendable {
    case giap = 0
    case at = 1
    case binh = 2
    case dinh = 3
    case mau = 4
    case ky = 5
    case canh = 6
    case tan = 7
    case nham = 8
    case quy = 9

    /// Vietnamese product text for this stem.
    public var vietnameseName: String {
        switch self {
        case .giap: "Giáp"
        case .at: "Ất"
        case .binh: "Bính"
        case .dinh: "Đinh"
        case .mau: "Mậu"
        case .ky: "Kỷ"
        case .canh: "Canh"
        case .tan: "Tân"
        case .nham: "Nhâm"
        case .quy: "Quý"
        }
    }
}
