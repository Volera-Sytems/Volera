import SwiftUI

struct EmptyFavoritesView: View {
    let accent: Color
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.dashed")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(accent.opacity(0.9))
                .shadow(color: accent.opacity(0.35), radius: 12)

            VStack(spacing: 6) {
                Text("No shortcuts yet")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))

                Text("Add favorite apps in Settings and they will appear here as launch tiles.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(VoleraPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }

            Button("Open Settings", action: onOpenSettings)
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .controlSize(.regular)
                .padding(.top, 4)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(VoleraPalette.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 1, dash: [7, 6])
                        )
                        .foregroundStyle(accent.opacity(0.28))
                )
        )
    }
}

#Preview {
    EmptyFavoritesView(accent: VoleraPalette.icyBlue, onOpenSettings: {})
        .padding(40)
        .background(VoleraPalette.charcoal)
}
