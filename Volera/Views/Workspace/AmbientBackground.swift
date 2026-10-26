import SwiftUI

struct AmbientBackground: View {
    let background: WorkspaceBackground
    let accent: Color
    var wallpaperImage: NSImage?
    var showsAtmosphere: Bool = true

    var body: some View {
        ZStack {
            fill
            if showsAtmosphere {
                atmosphere
            }
            readabilityOverlay
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.28), value: background.kind)
        .animation(.easeInOut(duration: 0.28), value: background.solidColor)
        .animation(.easeInOut(duration: 0.28), value: background.gradientStart)
        .animation(.easeInOut(duration: 0.28), value: background.gradientEnd)
        .animation(.easeInOut(duration: 0.28), value: background.wallpaperStoredFileName)
    }

    @ViewBuilder
    private var fill: some View {
        switch background.kind {
        case .solid:
            background.solidColor.color
        case .gradient:
            LinearGradient(
                colors: [
                    background.gradientStart.color,
                    background.gradientEnd.color
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .wallpaper:
            if let wallpaperImage {
                Image(nsImage: wallpaperImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        background.gradientStart.color,
                        background.gradientEnd.color
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var atmosphere: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(background.kind == .wallpaper ? 0.08 : 0.16))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: 240, y: -220)

            Circle()
                .fill(accent.opacity(background.kind == .wallpaper ? 0.04 : 0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -280, y: 260)
        }
        .allowsHitTesting(false)
    }

    private var readabilityOverlay: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(background.overlayOpacity + 0.08),
                Color.black.opacity(max(background.overlayOpacity - 0.16, 0.08)),
                Color.black.opacity(background.overlayOpacity + 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}

#Preview {
    AmbientBackground(
        background: .default,
        accent: VoleraPalette.icyBlue
    )
}
