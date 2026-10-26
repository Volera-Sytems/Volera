import SwiftUI

enum BackgroundTheme: String, CaseIterable, Identifiable, Codable {
    case charcoalIce
    case midnight
    case obsidian
    case arcticDusk
    case graphite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .charcoalIce: "Charcoal Ice"
        case .midnight: "Midnight"
        case .obsidian: "Obsidian"
        case .arcticDusk: "Arctic Dusk"
        case .graphite: "Graphite"
        }
    }

    var start: CodableColor {
        switch self {
        case .charcoalIce: CodableColor(red: 0.06, green: 0.08, blue: 0.10)
        case .midnight: CodableColor(red: 0.03, green: 0.05, blue: 0.12)
        case .obsidian: CodableColor(red: 0.04, green: 0.04, blue: 0.05)
        case .arcticDusk: CodableColor(red: 0.07, green: 0.08, blue: 0.16)
        case .graphite: CodableColor(red: 0.10, green: 0.11, blue: 0.12)
        }
    }

    var end: CodableColor {
        switch self {
        case .charcoalIce: CodableColor(red: 0.12, green: 0.22, blue: 0.30)
        case .midnight: CodableColor(red: 0.10, green: 0.16, blue: 0.34)
        case .obsidian: CodableColor(red: 0.16, green: 0.16, blue: 0.18)
        case .arcticDusk: CodableColor(red: 0.20, green: 0.16, blue: 0.32)
        case .graphite: CodableColor(red: 0.20, green: 0.22, blue: 0.24)
        }
    }

    var meshColors: [Color] {
        switch self {
        case .charcoalIce:
            [
                Color(red: 0.06, green: 0.08, blue: 0.10),
                Color(red: 0.09, green: 0.14, blue: 0.20),
                Color(red: 0.05, green: 0.07, blue: 0.10),
                Color(red: 0.08, green: 0.10, blue: 0.13),
                Color(red: 0.14, green: 0.22, blue: 0.30),
                Color(red: 0.07, green: 0.10, blue: 0.14),
                Color(red: 0.04, green: 0.05, blue: 0.07),
                Color(red: 0.08, green: 0.11, blue: 0.15),
                Color(red: 0.05, green: 0.08, blue: 0.12)
            ]
        case .midnight:
            [
                Color(red: 0.03, green: 0.05, blue: 0.12),
                Color(red: 0.06, green: 0.10, blue: 0.22),
                Color(red: 0.04, green: 0.05, blue: 0.10),
                Color(red: 0.05, green: 0.08, blue: 0.18),
                Color(red: 0.10, green: 0.16, blue: 0.32),
                Color(red: 0.04, green: 0.08, blue: 0.16),
                Color(red: 0.02, green: 0.03, blue: 0.08),
                Color(red: 0.06, green: 0.09, blue: 0.18),
                Color(red: 0.03, green: 0.05, blue: 0.12)
            ]
        case .obsidian:
            [
                Color(red: 0.05, green: 0.05, blue: 0.06),
                Color(red: 0.10, green: 0.10, blue: 0.12),
                Color(red: 0.04, green: 0.04, blue: 0.05),
                Color(red: 0.08, green: 0.08, blue: 0.09),
                Color(red: 0.16, green: 0.16, blue: 0.18),
                Color(red: 0.07, green: 0.07, blue: 0.08),
                Color(red: 0.03, green: 0.03, blue: 0.03),
                Color(red: 0.09, green: 0.09, blue: 0.10),
                Color(red: 0.05, green: 0.05, blue: 0.06)
            ]
        case .arcticDusk:
            [
                Color(red: 0.07, green: 0.08, blue: 0.14),
                Color(red: 0.12, green: 0.16, blue: 0.26),
                Color(red: 0.10, green: 0.09, blue: 0.16),
                Color(red: 0.08, green: 0.12, blue: 0.20),
                Color(red: 0.18, green: 0.22, blue: 0.34),
                Color(red: 0.14, green: 0.12, blue: 0.22),
                Color(red: 0.05, green: 0.06, blue: 0.10),
                Color(red: 0.10, green: 0.11, blue: 0.18),
                Color(red: 0.08, green: 0.08, blue: 0.14)
            ]
        case .graphite:
            [
                Color(red: 0.10, green: 0.11, blue: 0.12),
                Color(red: 0.16, green: 0.17, blue: 0.18),
                Color(red: 0.08, green: 0.09, blue: 0.10),
                Color(red: 0.12, green: 0.13, blue: 0.14),
                Color(red: 0.20, green: 0.22, blue: 0.24),
                Color(red: 0.11, green: 0.12, blue: 0.13),
                Color(red: 0.07, green: 0.08, blue: 0.08),
                Color(red: 0.14, green: 0.15, blue: 0.16),
                Color(red: 0.09, green: 0.10, blue: 0.11)
            ]
        }
    }
}
