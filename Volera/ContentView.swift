import SwiftUI

struct ContentView: View {
    @Environment(SettingsStore.self) private var store
    @State private var destination: AppDestination = .workspace

    var body: some View {
        @Bindable var store = store

        NavigationSplitView {
            AppSidebar(destination: $destination, accent: store.accentColor)
        } detail: {
            switch destination {
            case .workspace:
                WorkspaceView(store: store, destination: $destination)
            case .settings:
                SettingsView(store: store)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background {
            AmbientBackground(
                background: store.preferences.background,
                accent: store.accentColor,
                wallpaperImage: store.wallpaperImage,
                showsAtmosphere: false
            )
        }
        .tint(store.accentColor)
    }
}

#Preview {
    ContentView()
        .environment(SettingsStore())
        .frame(width: 1100, height: 720)
}
