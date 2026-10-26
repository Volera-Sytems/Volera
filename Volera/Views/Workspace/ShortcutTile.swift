import AppKit
import SwiftUI

struct ShortcutTile: View {
    let shortcut: AppShortcut
    let accent: Color
    var onOpen: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 14) {
                icon
                    .frame(width: 56, height: 56)
                    .shadow(color: accent.opacity(hovering ? 0.4 : 0.15), radius: hovering ? 20 : 10, y: 6)
                    .scaleEffect(hovering ? 1.05 : 1.0)

                Text(shortcut.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(hovering ? 1.0 : 0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 20)
            .frame(width: 140, height: 140)
            .background(
                RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius, style: .continuous)
                    .fill(VoleraPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius, style: .continuous)
                            .stroke(hovering ? accent.opacity(0.5) : VoleraPalette.panelStroke, lineWidth: 1.5)
                    )
                    .shadow(color: hovering ? accent.opacity(0.25) : .black.opacity(0.3), radius: hovering ? 25 : 12, y: 10)
            )
            .scaleEffect(hovering ? 1.04 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hovering)
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
