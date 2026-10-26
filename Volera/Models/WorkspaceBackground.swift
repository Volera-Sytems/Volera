import Foundation

enum BackgroundKind: String, CaseIterable, Identifiable, Codable {
    case solid
    case gradient
    case wallpaper

    var id: String { rawValue }

    var title: String {
        switch self {
        case .solid: "Solid"
        case .gradient: "Gradient"
        case .wallpaper: "Image"
        }
    }
}

struct SolidPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let color: CodableColor

    static let all: [SolidPreset] = [
        SolidPreset(id: "charcoal", title: "Charcoal", color: CodableColor(red: 0.07, green: 0.08, blue: 0.10)),
        SolidPreset(id: "midnight", title: "Midnight", color: CodableColor(red: 0.04, green: 0.06, blue: 0.12)),
        SolidPreset(id: "obsidian", title: "Obsidian", color: CodableColor(red: 0.05, green: 0.05, blue: 0.06)),
        SolidPreset(id: "graphite", title: "Graphite", color: CodableColor(red: 0.13, green: 0.14, blue: 0.16)),
        SolidPreset(id: "deepIce", title: "Deep Ice", color: CodableColor(red: 0.08, green: 0.14, blue: 0.20))
    ]
}

struct WorkspaceBackground: Codable, Equatable {
    var kind: BackgroundKind
    var solidColor: CodableColor
    var gradientStart: CodableColor
    var gradientEnd: CodableColor
    var wallpaperBookmark: Data?
    var wallpaperStoredFileName: String?
    var wallpaperOriginalName: String?

    static let `default` = WorkspaceBackground(preset: .charcoalIce)

    init(
        kind: BackgroundKind,
        solidColor: CodableColor,
        gradientStart: CodableColor,
        gradientEnd: CodableColor,
        wallpaperBookmark: Data? = nil,
        wallpaperStoredFileName: String? = nil,
        wallpaperOriginalName: String? = nil
    ) {
        self.kind = kind
        self.solidColor = solidColor
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
        self.wallpaperBookmark = wallpaperBookmark
        self.wallpaperStoredFileName = wallpaperStoredFileName
        self.wallpaperOriginalName = wallpaperOriginalName
    }

    init(preset: BackgroundTheme) {
        self.kind = .gradient
        self.solidColor = preset.start
        self.gradientStart = preset.start
        self.gradientEnd = preset.end
        self.wallpaperBookmark = nil
        self.wallpaperStoredFileName = nil
        self.wallpaperOriginalName = nil
    }

    var hasWallpaper: Bool {
        wallpaperStoredFileName != nil || wallpaperBookmark != nil
    }

    var overlayOpacity: Double {
        switch kind {
        case .solid:
            return solidColor.relativeLuminance > 0.42 ? 0.46 : 0.22
        case .gradient:
            let luminance = (gradientStart.relativeLuminance + gradientEnd.relativeLuminance) / 2
            return luminance > 0.42 ? 0.48 : 0.26
        case .wallpaper:
            return 0.48
        }
    }
}
