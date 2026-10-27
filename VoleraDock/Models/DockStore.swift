import AppKit
import Observation
import ServiceManagement

@MainActor
@Observable
final class DockStore {
    var configuration: DockConfiguration {
        didSet { persist() }
    }
    private(set) var statusMessage = "Your floating dock is ready."
    private(set) var errorMessage: String?

    private let defaultsKey = "dev.volera.dock.configuration"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: defaultsKey),
           let stored = try? JSONDecoder().decode(DockConfiguration.self, from: data) {
            var restored = stored
            restored.isVisible = false
            configuration = restored
        } else {
            configuration = .defaults
        }
    }

    func addApplications(from urls: [URL]) {
        var next = configuration.apps
        for url in urls {
            do {
                let item = try DockAppItem.make(from: url)
                guard !next.contains(where: { existing in
                    if let identifier = item.bundleIdentifier {
                        return existing.bundleIdentifier == identifier
                    }
                    return existing.path == item.path
                }) else { continue }
                next.append(item)
            } catch {
                report(error.localizedDescription)
            }
        }
        configuration.apps = next
        if !urls.isEmpty, errorMessage == nil {
            statusMessage = "Added \(urls.count == 1 ? "application" : "applications") to your dock."
        }
    }

    func remove(_ item: DockAppItem) {
        configuration.apps.removeAll { $0.id == item.id }
        statusMessage = "Removed \(item.name) from the dock."
        errorMessage = nil
    }

    func move(_ sourceID: String, before destinationID: String) {
        guard let sourceIndex = configuration.apps.firstIndex(where: { $0.id.uuidString == sourceID }),
              let destinationIndex = configuration.apps.firstIndex(where: { $0.id.uuidString == destinationID }),
              sourceIndex != destinationIndex else {
            return
        }
        var updated = configuration.apps
        let item = updated.remove(at: sourceIndex)
        let insertionIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
        updated.insert(item, at: insertionIndex)
        configuration.apps = updated
    }

    func launch(_ item: DockAppItem, tracker: ApplicationTracker) {
        do {
            let url = try item.resolvedURL()
            let startedAccessing = url.startAccessingSecurityScopedResource()
            let openConfiguration = NSWorkspace.OpenConfiguration()
            openConfiguration.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: openConfiguration) { [weak self, weak tracker] application, error in
                if startedAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
                Task { @MainActor [weak self, weak tracker] in
                    if let error {
                        self?.report("Could not launch \(item.name): \(error.localizedDescription)")
                    } else {
                        self?.statusMessage = "Opened \(application?.localizedName ?? item.name)."
                        self?.errorMessage = nil
                        tracker?.refresh()
                    }
                }
            }
        } catch {
            report(error.localizedDescription)
        }
    }

    func activate(_ application: NSRunningApplication, named name: String) {
        guard application.activate(options: [.activateAllWindows]) else {
            report("Could not activate \(name). The application may have exited.")
            return
        }
        statusMessage = "Switched to \(name)."
        errorMessage = nil
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            configuration.launchesAtLogin = enabled
            if enabled && SMAppService.mainApp.status == .requiresApproval {
                report("Approve Volera Dock in System Settings > General > Login Items to finish enabling login startup.")
            } else {
                statusMessage = enabled
                    ? "Volera Dock will open at login."
                    : "Volera Dock will not open automatically at login."
                errorMessage = nil
            }
        } catch {
            report("Could not update the login item: \(error.localizedDescription)")
            configuration.launchesAtLogin = false
        }
    }

    func restoreDefaults() {
        let existingApps = configuration.apps
        configuration = .defaults
        configuration.apps = existingApps
        statusMessage = "Appearance and behavior settings restored. Your apps were kept."
        errorMessage = nil
    }

    func report(_ message: String) {
        errorMessage = message
        statusMessage = message
    }

    func updateStatus(_ message: String, clearError: Bool = false) {
        statusMessage = message
        if clearError {
            errorMessage = nil
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
