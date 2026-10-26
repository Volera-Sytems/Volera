import AppKit
import SwiftUI

struct ShortcutTile: View {
    let shortcut: AppShortcut
    let accent: Color
    var onOpen: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 16) {
                icon
                    .frame(width: 64, height: 64)
                    .shadow(color: accent.opacity(hovering ? 0.45 : 0.18), radius: hovering ? 24 : 12, y: 8)
                    .scaleEffect(hovering ? 1.08 : 1.0)

                Text(shortcut.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(hovering ? 1.0 : 0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .frame(width: 160, height: 160)
            .background(
                RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius + 4, style: .continuous)
                    .fill(VoleraPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius + 4, style: .continuous)
                            .stroke(hovering ? accent.opacity(0.55) : VoleraPalette.panelStroke, lineWidth: 2)
                    )
                    .shadow(color: hovering ? accent.opacity(0.3) : .black.opacity(0.35), radius: hovering ? 30 : 15, y: 12)
            )
            .scaleEffect(hovering ? 1.05 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(shortcut.name)
        .accessibilityLabel("Open \(shortcut.name)")
    }

    @ViewBuilder
    private var icon: some View {
        if let url = shortcut.resolvedURL() {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Image(systemName: "app.fill")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(accent)
        }
    }
}

#Preview {
    ShortcutTile(
        shortcut: AppShortcut(name: "Safari", bundleIdentifier: "com.apple.Safari"),
        accent: VoleraPalette.icyBlue,
        onOpen: {}
    )
    .padding(40)
    .background(VoleraPalette.charcoal)
}
