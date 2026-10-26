import SwiftUI

struct FavoritesGrid: View {
    let shortcuts: [AppShortcut]
    let accent: Color
    var onOpen: (AppShortcut) -> Void
    var onOpenSettings: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 32)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 12) {
                Text("Workspace")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(1.5)
                    .textCase(.uppercase)

                Capsule()
                    .fill(accent.opacity(0.8))
                    .frame(width: 32, height: 3)
            }
            .padding(.leading, 4)

            if shortcuts.isEmpty {
                EmptyFavoritesView(accent: accent, onOpenSettings: onOpenSettings)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(shortcuts) { shortcut in
                        ShortcutTile(shortcut: shortcut, accent: accent) {
                            onOpen(shortcut)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    FavoritesGrid(shortcuts: [], accent: VoleraPalette.icyBlue, onOpen: { _ in }, onOpenSettings: {})
        .padding(40)
        .background(VoleraPalette.charcoal)
}
