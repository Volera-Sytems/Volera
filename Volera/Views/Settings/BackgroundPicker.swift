import SwiftUI
import UniformTypeIdentifiers

struct BackgroundPicker: View {
    @Bindable var store: SettingsStore
    @State private var isImporterPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            preview

            Picker("Background type", selection: kindBinding) {
                ForEach(BackgroundKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch store.preferences.background.kind {
            case .solid:
                solidControls
            case .gradient:
                gradientControls
            case .wallpaper:
                wallpaperControls
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                store.setWallpaper(from: url)
            }
        }
    }

    private var preview: some View {
        AmbientBackground(
            background: store.preferences.background,
            accent: store.accentColor,
            wallpaperImage: store.wallpaperImage
        )
        .frame(height: 128)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(store.accentColor.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: store.accentColor.opacity(0.12), radius: 12, y: 4)
        .overlay(alignment: .bottomLeading) {
            Text("Live preview")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }

    private var solidControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presets")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(VoleraPalette.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SolidPreset.all) { preset in
                        presetButton(
                            title: preset.title,
                            selected: store.preferences.background.solidColor == preset.color
                                && store.preferences.background.kind == .solid
                        ) {
                            store.applySolidPreset(preset)
                        } swatch: {
                            preset.color.color
                        }
                    }
                }
            }

            ColorPicker("Custom color", selection: solidBinding, supportsOpacity: false)
        }
    }

    private var gradientControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presets")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(VoleraPalette.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BackgroundTheme.allCases) { preset in
                        presetButton(
                            title: preset.title,
                            selected: store.preferences.background.kind == .gradient
                                && store.preferences.background.gradientStart == preset.start
                                && store.preferences.background.gradientEnd == preset.end
                        ) {
                            store.applyGradientPreset(preset)
                        } swatch: {
                            LinearGradient(
                                colors: [preset.start.color, preset.end.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                }
            }

            ColorPicker("Start color", selection: gradientStartBinding, supportsOpacity: false)
            ColorPicker("End color", selection: gradientEndBinding, supportsOpacity: false)
        }
    }

    private var wallpaperControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                wallpaperThumb
                    .frame(width: 72, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.preferences.background.wallpaperOriginalName ?? "No image selected")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                    Text("Copied into Volera so it stays available after relaunch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    isImporterPresented = true
                } label: {
                    Label("Choose Image…", systemImage: "photo")
                }

                if store.preferences.background.hasWallpaper {
                    Button("Remove Image", role: .destructive) {
                        store.clearWallpaper()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var wallpaperThumb: some View {
        if let wallpaperImage = store.wallpaperImage {
            Image(nsImage: wallpaperImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                VoleraPalette.charcoalLift
                Image(systemName: "photo")
                    .foregroundStyle(store.accentColor)
            }
        }
    }

    private func presetButton<Swatch: View>(
        title: String,
        selected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder swatch: () -> Swatch
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                swatch()
                    .frame(width: 54, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selected ? store.accentColor : Color.white.opacity(0.08), lineWidth: selected ? 2 : 1)
                    )
                    .shadow(color: selected ? store.accentColor.opacity(0.28) : .clear, radius: 8)

                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(selected ? .white : VoleraPalette.secondaryText)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .help(title)
    }

    private var kindBinding: Binding<BackgroundKind> {
        Binding(
            get: { store.preferences.background.kind },
            set: { kind in
                var background = store.preferences.background
                background.kind = kind
                store.preferences.background = background
            }
        )
    }

    private var solidBinding: Binding<Color> {
        Binding(
            get: { store.preferences.background.solidColor.color },
            set: { color in
                var background = store.preferences.background
                background.kind = .solid
                background.solidColor = CodableColor(color)
                store.preferences.background = background
            }
        )
    }

    private var gradientStartBinding: Binding<Color> {
        Binding(
            get: { store.preferences.background.gradientStart.color },
            set: { color in
                var background = store.preferences.background
                background.kind = .gradient
                background.gradientStart = CodableColor(color)
                store.preferences.background = background
            }
        )
    }

    private var gradientEndBinding: Binding<Color> {
        Binding(
            get: { store.preferences.background.gradientEnd.color },
            set: { color in
                var background = store.preferences.background
                background.kind = .gradient
                background.gradientEnd = CodableColor(color)
                store.preferences.background = background
            }
        )
    }
}
