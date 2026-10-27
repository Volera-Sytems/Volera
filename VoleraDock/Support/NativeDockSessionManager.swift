import AppKit
import Observation

@MainActor
@Observable
final class NativeDockSessionManager {
    static let shared = NativeDockSessionManager()

    private(set) var isActive = false
    private(set) var isStarting = false
    private(set) var isStopping = false

    @ObservationIgnored private weak var store: DockStore?
    @ObservationIgnored private var previousPresentationOptions: NSApplication.PresentationOptions?

    private init() {}

    func configure(store: DockStore) {
        self.store = store
    }

    func start(completion: @escaping @MainActor (Result<Void, Error>) -> Void) {
        guard !isActive, !isStarting, !isStopping else {
            completion(.failure(SessionError.operationInProgress))
            return
        }

        isStarting = true
        previousPresentationOptions = NSApp.presentationOptions
        NSApp.presentationOptions.formUnion(.autoHideDock)
        isActive = true
        isStarting = false

        if let store {
            store.configuration.isVisible = true
            DockWindowController.shared.beginSession()
            store.updateStatus(
                "Volera is active. The native Dock auto-hide preference is controlled by macOS and remains unchanged by Volera.",
                clearError: true
            )
        }
        completion(.success(()))
    }

    func stop(completion: @escaping @MainActor (Result<Void, Error>) -> Void) {
        guard !isStarting, !isStopping else {
            completion(.failure(SessionError.operationInProgress))
            return
        }

        isStopping = true
        NSApp.presentationOptions = previousPresentationOptions ??
            NSApp.presentationOptions.subtracting(.autoHideDock)
        previousPresentationOptions = nil
        finishSession()
        isStopping = false
        completion(.success(()))
    }

    private func finishSession() {
        isActive = false
        DockWindowController.shared.endSession()
        if let store {
            store.configuration.isVisible = false
            store.updateStatus(
                "Volera session ended. Any native Dock auto-hide setting you changed with ⌥⌘D remains in effect until you toggle it again.",
                clearError: true
            )
        }
    }
}

private enum SessionError: LocalizedError {
    case operationInProgress

    var errorDescription: String? {
        "Wait for the Volera session operation to finish before continuing."
    }
}
