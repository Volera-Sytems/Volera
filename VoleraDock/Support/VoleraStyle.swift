import AppKit
import SwiftUI

enum VoleraStyle {
    static let canvas = Color(hex: 0x0C111A)
    static let panel = Color(hex: 0x151C28)
    static let panelRaised = Color(hex: 0x1B2533)
    static let line = Color.white.opacity(0.09)
    static let blue = Color(hex: 0x78A9FF)
    static let paleBlue = Color(hex: 0xC8D8F7)
    static let muted = Color(hex: 0x8995A7)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    @MainActor
    var rgbHex: UInt32 {
        let color = NSColor(self).usingColorSpace(.deviceRGB) ?? .black
        return (UInt32(color.redComponent * 255) << 16) |
            (UInt32(color.greenComponent * 255) << 8) |
            UInt32(color.blueComponent * 255)
    }
}

@MainActor
final class DockIconCache {
    static let shared = DockIconCache()

    private let cache = NSCache<NSString, NSImage>()

    func icon(for item: DockAppItem) -> NSImage? {
        let key = (item.bundleIdentifier ?? item.path) as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let url = try? item.resolvedURL() else { return nil }
        let startedAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if startedAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(icon, forKey: key)
        return icon
    }
}

@MainActor
struct DockApplicationIcon: View {
    let item: DockAppItem
    let size: CGFloat
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(VoleraStyle.paleBlue.opacity(0.72))
                    .padding(size * 0.18)
            }
        }
        .frame(width: size, height: size)
        .task(id: item.path) {
            image = DockIconCache.shared.icon(for: item)
        }
    }
}
