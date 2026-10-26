import AppKit
import SwiftUI

struct ShortcutTile: View {
    let shortcut: AppShortcut
    let accent: Color
    var onOpen: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 12) {
                icon
                    .frame(width: 52, height: 52)
                    .shadow(color: accent.opacity(hovering ? 0.35 : 0.12), radius: hovering ? 16 : 8, y: 4)

                Text(shortcut.name)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 18)
            .frame(width: 132, height: 132)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(VoleraPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(hovering ? accent.opacity(0.45) : VoleraPalette.panelStroke, lineWidth: 1)
                    )
                    .shadow(color: hovering ? accent.opacity(0.18) : .black.opacity(0.24), radius: hovering ? 18 : 10, y: 8)
            )
            .scaleEffect(hovering ? 1.03 : 1)
            .animation(.easeOut(duration: 0.18), value: hovering)
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
