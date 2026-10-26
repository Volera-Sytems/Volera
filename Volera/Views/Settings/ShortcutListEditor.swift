import SwiftUI
import UniformTypeIdentifiers

struct ShortcutListEditor: View {
    @Bindable var store: SettingsStore
    @State private var isImporterPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.preferences.shortcuts.isEmpty {
                Text("No favorite apps yet. Choose applications to pin to the workspace.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(store.preferences.shortcuts) { shortcut in
                    HStack(spacing: 12) {
                        ShortcutIcon(shortcut: shortcut)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(shortcut.name)
                            if let bundleIdentifier = shortcut.bundleIdentifier {
                                Text(bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button(role: .destructive) {
                            store.removeShortcut(shortcut)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove \(shortcut.name)")
                    }
                    .padding(.vertical, 2)
                }
            }

            Button {
                isImporterPresented = true
            } label: {
                Label("Add Application", systemImage: "plus")
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.application],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                store.addShortcuts(from: urls)
            }
        }
    }
}

private struct ShortcutIcon: View {
    let shortcut: AppShortcut

    var body: some View {
        if let url = shortcut.resolvedURL() {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Image(systemName: "app.fill")
                .foregroundStyle(VoleraPalette.icyBlue)
        }
    }
}
