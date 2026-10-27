import AppKit
import Foundation
import SwiftUI

enum DockTheme: String, CaseIterable, Codable, Identifiable {
    case midnight
    case aurora
    case minimal
    case classic
    case custom

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var values: ThemeValues {
        switch self {
        case .midnight:
            ThemeValues(backgroundHex: 0x111722, opacity: 0.78, cornerRadius: 28, shadow: 0.42, border: true)
        case .aurora:
            ThemeValues(backgroundHex: 0x10233A, opacity: 0.72, cornerRadius: 30, shadow: 0.48, border: true)
        case .minimal:
            ThemeValues(backgroundHex: 0x0C1015, opacity: 0.94, cornerRadius: 18, shadow: 0.20, border: false)
        case .classic:
            ThemeValues(backgroundHex: 0x292A30, opacity: 0.88, cornerRadius: 24, shadow: 0.34, border: true)
        case .custom:
            ThemeValues(backgroundHex: DockTheme.midnight.values.backgroundHex, opacity: 0.78, cornerRadius: 28, shadow: 0.42, border: true)
        }
    }
}

struct ThemeValues {
    let backgroundHex: UInt32
    let opacity: Double
    let cornerRadius: Double
    let shadow: Double
    let border: Bool
}

enum DockAppearance: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    @MainActor
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum DockPosition: String, CaseIterable, Codable, Identifiable {
    case bottom
    case left
    case right

    var id: String { rawValue }
}

struct DockConfiguration: Codable, Equatable {
    var apps: [DockAppItem] = []
    var theme: DockTheme = .midnight
    var appearance: DockAppearance = .system
    var backgroundHex: UInt32 = DockTheme.midnight.values.backgroundHex
    var backgroundOpacity = DockTheme.midnight.values.opacity
    var cornerRadius = DockTheme.midnight.values.cornerRadius
    var shadowIntensity = DockTheme.midnight.values.shadow
    var showsBorder = DockTheme.midnight.values.border
    var iconSize = 54.0
    var iconSpacing = 12.0
    var hoverMagnification = 1.12
    var animationDuration = 0.20
    var showsRunningIndicators = true
    var showsHoverEffects = true
    var position: DockPosition = .bottom
    var edgeOffset = 18.0
    var selectedDisplayID: String?
    var isVisible = false
    var launchesAtLogin = false

    mutating func apply(_ theme: DockTheme) {
        self.theme = theme
        let values = theme.values
        backgroundHex = values.backgroundHex
        backgroundOpacity = values.opacity
        cornerRadius = values.cornerRadius
        shadowIntensity = values.shadow
        showsBorder = values.border
        switch theme {
        case .midnight:
            iconSize = 54
            iconSpacing = 12
        case .aurora:
            iconSize = 56
            iconSpacing = 14
        case .minimal:
            iconSize = 46
            iconSpacing = 8
        case .classic, .custom:
            iconSize = 52
            iconSpacing = 10
        }
    }

    mutating func markCustom() {
        theme = .custom
    }
}

extension DockConfiguration {
    static let defaults = DockConfiguration()
}
