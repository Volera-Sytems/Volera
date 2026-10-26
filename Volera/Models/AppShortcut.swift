import AppKit
import Foundation

struct AppShortcut: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var bundleIdentifier: String?
    var path: String?
    var bookmarkData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String? = nil,
        path: String? = nil,
        bookmarkData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.bookmarkData = bookmarkData
    }

    init?(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let resolved = url.standardizedFileURL
        guard FileManager.default.fileExists(atPath: resolved.path) else { return nil }

        self.id = UUID()
        self.name = FileManager.default.displayName(atPath: resolved.path)
        self.bundleIdentifier = Bundle(url: resolved)?.bundleIdentifier
        self.path = resolved.path
        self.bookmarkData = try? resolved.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    func resolvedURL() -> URL? {
        if let bookmarkData {
            var stale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) {
                return url
            }
        }

        if let bundleIdentifier,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return url
        }

        if let path {
            return URL(fileURLWithPath: path)
        }

        return nil
    }
}
