import AppKit
import Foundation

struct DockAppItem: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var bundleIdentifier: String?
    var path: String
    var bookmarkData: Data?

    init(id: UUID = UUID(), name: String, bundleIdentifier: String?, path: String, bookmarkData: Data?) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.bookmarkData = bookmarkData
    }

    @MainActor
    static func make(from url: URL) throws -> DockAppItem {
        let startedAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if startedAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: url.path),
              let bundle = Bundle(url: url) else {
            throw DockAppItemError.notAnApplication
        }

        let bookmark = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
        return DockAppItem(
            name: FileManager.default.displayName(atPath: url.path),
            bundleIdentifier: bundle.bundleIdentifier,
            path: url.path,
            bookmarkData: bookmark
        )
    }

    @MainActor
    func resolvedURL() throws -> URL {
        if let bookmarkData {
            var stale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ), !stale {
                return url
            }
        }

        if let bundleIdentifier,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return url
        }

        let fallbackURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: fallbackURL.path) else {
            throw DockAppItemError.applicationMoved
        }
        return fallbackURL
    }

    @MainActor
    func isAvailable() -> Bool {
        guard let url = try? resolvedURL() else { return false }
        let startedAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if startedAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return FileManager.default.fileExists(atPath: url.path)
    }
}

enum DockAppItemError: LocalizedError {
    case notAnApplication
    case applicationMoved

    var errorDescription: String? {
        switch self {
        case .notAnApplication:
            "The selected item is not a valid macOS application."
        case .applicationMoved:
            "This application could not be found. Remove it and add it again from its new location."
        }
    }
}
