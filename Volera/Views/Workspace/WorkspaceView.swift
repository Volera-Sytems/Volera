import SwiftUI

struct WorkspaceView: View {
    @Bindable var store: SettingsStore
    @Binding var destination: AppDestination

    var body: some View {
        ZStack {
            AmbientBackground(
                background: store.preferences.background,
                accent: store.accentColor,
                wallpaperImage: store.wallpaperImage
            )

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                if store.preferences.showClock || store.preferences.showDate {
                    ClockPanel(
                        showClock: store.preferences.showClock,
                        showDate: store.preferences.showDate,
                        accent: store.accentColor
                    )
                    .padding(.bottom, 28)
                }

                Spacer(minLength: 12)

                FavoritesGrid(
                    shortcuts: store.preferences.shortcuts,
                    accent: store.accentColor,
                    onOpen: store.openShortcut,
                    onOpenSettings: { destination = .settings }
                )
                .padding(.horizontal, 8)

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 28)
        }
        .navigationTitle("Workspace")
    }
}
