import AppKit
import Foundation
import Observation
import SwiftUI

@Observable
final class SettingsStore {
    var preferences: WorkspacePreferences {
        didSet { persist() }
    }

    var wallpaperImage: NSImage?

    private let defaultsKey = "volera.workspace.preferences"

    init(defaults: UserDefaults = .standard) {
        if let data = defaults.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(WorkspacePreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = .default
        }
        wallpaperImage = Self.loadWallpaperImage(from: preferences.background)
    }

    var accentColor: Color {
        preferences.accent.color
    }

    func addShortcuts(from urls: [URL]) {
        var next = preferences.shortcuts
        for url in urls {
            guard let shortcut = AppShortcut(url: url) else { continue }
            let duplicate = next.contains { existing in
                if let lhs = existing.bundleIdentifier, let rhs = shortcut.bundleIdentifier {
                    return lhs == rhs
                }
                return existing.path == shortcut.path
            }
            if !duplicate {
                next.append(shortcut)
            }
        }
        preferences.shortcuts = next
    }

    func removeShortcut(_ shortcut: AppShortcut) {
        preferences.shortcuts.removeAll { $0.id == shortcut.id }
    }

    func openShortcut(_ shortcut: AppShortcut) {
        guard let url = shortcut.resolvedURL() else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func applySolidPreset(_ preset: SolidPreset) {
        var background = preferences.background
        background.kind = .solid
        background.solidColor = preset.color
        preferences.background = background
    }

    func applyGradientPreset(_ preset: BackgroundTheme) {
        var background = preferences.background
        background.kind = .gradient
        background.gradientStart = preset.start
        background.gradientEnd = preset.end
        preferences.background = background
    }

    func setWallpaper(from url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let storedURL = Self.copyWallpaper(from: url) else { return }
        let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        var background = preferences.background
        background.kind = .wallpaper
        background.wallpaperBookmark = bookmark
        background.wallpaperStoredFileName = storedURL.lastPathComponent
        background.wallpaperOriginalName = FileManager.default.displayName(atPath: url.path)
        preferences.background = background
        wallpaperImage = NSImage(contentsOf: storedURL)
    }

    func clearWallpaper() {
        Self.removeStoredWallpapers()
        var background = preferences.background
        background.wallpaperBookmark = nil
        background.wallpaperStoredFileName = nil
        background.wallpaperOriginalName = nil
        if background.kind == .wallpaper {
            background.kind = .gradient
        }
        preferences.background = background
        wallpaperImage = nil
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private static func wallpaperDirectory() throws -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = root.appendingPathComponent("Volera/Wallpapers", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func copyWallpaper(from url: URL) -> URL? {
        do {
            let directory = try wallpaperDirectory()
            removeStoredWallpapers()
            let fileName = "wallpaper.\(url.pathExtension.isEmpty ? "png" : url.pathExtension.lowercased())"
            let destination = directory.appendingPathComponent(fileName)
            try FileManager.default.copyItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    private static func removeStoredWallpapers() {
        guard let directory = try? wallpaperDirectory() else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private static func loadWallpaperImage(from background: WorkspaceBackground) -> NSImage? {
        if let fileName = background.wallpaperStoredFileName,
           let directory = try? wallpaperDirectory() {
            let storedURL = directory.appendingPathComponent(fileName)
            if let image = NSImage(contentsOf: storedURL) {
                return image
            }
        }

        guard let bookmark = background.wallpaperBookmark else { return nil }
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else { return nil }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if let copied = copyWallpaper(from: url), let image = NSImage(contentsOf: copied) {
            return image
        }
        return NSImage(contentsOf: url)
    }
}
