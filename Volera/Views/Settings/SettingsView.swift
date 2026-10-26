import SwiftUI

struct SettingsView: View {
    @Bindable var store: SettingsStore

    var body: some View {
        ZStack {
            AmbientBackground(
                background: store.preferences.background,
                accent: store.accentColor,
                wallpaperImage: store.wallpaperImage
            )

            Form {
                Section("Background") {
                    BackgroundPicker(store: store)
                }

                Section("Appearance") {
                    ColorPicker("Accent Color", selection: accentBinding, supportsOpacity: false)
                }

                Section("Clock") {
                    Toggle("Show clock", isOn: $store.preferences.showClock)
                    Toggle("Show date", isOn: $store.preferences.showDate)
                }

                Section("Favorites") {
                    ShortcutListEditor(store: store)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .padding(8)
        }
        .navigationTitle("Settings")
        .tint(store.accentColor)
    }

    private var accentBinding: Binding<Color> {
        Binding(
            get: { store.accentColor },
            set: { store.preferences.accent = CodableColor($0) }
        )
    }
}
