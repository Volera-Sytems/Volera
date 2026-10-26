import SwiftUI

struct FavoritesGrid: View {
    let shortcuts: [AppShortcut]
    let accent: Color
    var onOpen: (AppShortcut) -> Void
    var onOpenSettings: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 132, maximum: 148), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Text("Favorites")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .tracking(1.2)
                    .textCase(.uppercase)

                Capsule()
                    .fill(accent.opacity(0.7))
                    .frame(width: 28, height: 2)
            }

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
