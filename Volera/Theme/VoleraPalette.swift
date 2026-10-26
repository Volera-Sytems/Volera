import AppKit
import SwiftUI

enum VoleraPalette {
    static let charcoal = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let charcoalLift = Color(red: 0.12, green: 0.14, blue: 0.17)
    static let panel = Color(red: 0.14, green: 0.16, blue: 0.19).opacity(0.72)
    static let panelStroke = Color.white.opacity(0.08)
    static let icyBlue = Color(red: 0.55, green: 0.80, blue: 0.96)
    static let mist = Color.white.opacity(0.72)
    static let secondaryText = Color.white.opacity(0.46)
}

struct CodableColor: Codable, Equatable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    static let icyBlue = CodableColor(red: 0.55, green: 0.80, blue: 0.96, opacity: 1)

    var relativeLuminance: Double {
        (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    init(_ color: Color) {
        let source = NSColor(color)
        let resolved = source.usingColorSpace(.extendedSRGB) ?? source.usingColorSpace(.sRGB) ?? NSColor.black
        self.red = Self.clamp(resolved.redComponent)
        self.green = Self.clamp(resolved.greenComponent)
        self.blue = Self.clamp(resolved.blueComponent)
        self.opacity = Self.clamp(resolved.alphaComponent)
    }

    private static func clamp(_ value: CGFloat) -> Double {
        min(max(Double(value), 0), 1)
    }
}
