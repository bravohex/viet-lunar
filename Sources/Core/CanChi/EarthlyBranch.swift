import Foundation

/// The twelve earthly branches in their canonical cycle order.
public enum EarthlyBranch: Int, CaseIterable, Codable, Sendable {
    case ty = 0
    case suu = 1
    case dan = 2
    case mao = 3
    case thin = 4
    case tySnake = 5
    case ngo = 6
    case mui = 7
    case than = 8
    case dau = 9
    case tuat = 10
    case hoi = 11

    /// Vietnamese product text for this branch.
    public var vietnameseName: String {
        switch self {
        case .ty: "Tý"
        case .suu: "Sửu"
        case .dan: "Dần"
        case .mao: "Mão"
        case .thin: "Thìn"
        case .tySnake: "Tỵ"
        case .ngo: "Ngọ"
        case .mui: "Mùi"
        case .than: "Thân"
        case .dau: "Dậu"
        case .tuat: "Tuất"
        case .hoi: "Hợi"
        }
    }
}
