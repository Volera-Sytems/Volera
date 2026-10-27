import AppKit
import Observation

@MainActor
@Observable
final class ApplicationTracker {
    private(set) var runningApplications: [NSRunningApplication] = []
    private(set) var frontmostBundleIdentifier: String?

    private let notificationCenter = NSWorkspace.shared.notificationCenter
    private var observerTokens: [NSObjectProtocol] = []

    init() {
        for name in [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification
        ] {
            observerTokens.append(
                notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    Task { @MainActor [weak self] in self?.refresh() }
                }
            )
        }
        refresh()
    }

    isolated deinit {
        for token in observerTokens {
            notificationCenter.removeObserver(token)
        }
    }

    func refresh() {
        runningApplications = NSWorkspace.shared.runningApplications.filter {
            !$0.isTerminated && $0.activationPolicy == .regular
        }
        frontmostBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    func application(for item: DockAppItem) -> NSRunningApplication? {
        guard let identifier = item.bundleIdentifier else { return nil }
        return runningApplications.first { $0.bundleIdentifier == identifier }
    }
}
