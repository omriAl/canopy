import Foundation

enum Terminal: String, Codable, CaseIterable {
    case iterm2 = "iterm2"
    case warp = "warp"

    var displayName: String {
        switch self {
        case .iterm2: return "iTerm2"
        case .warp: return "Warp"
        }
    }
}
