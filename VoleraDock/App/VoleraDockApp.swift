import AppKit
import SwiftUI

@main
@MainActor
struct VoleraDockApp: App {
    @NSApplicationDelegateAdaptor(VoleraDockAppDelegate.self) private var appDelegate
    @State private var store = DockStore()
    @State private var tracker = ApplicationTracker()
    @State private var sessionManager = NativeDockSessionManager.shared

    var body: some Scene {
        WindowGroup("Volera Dock", id: "main") {
            DockDashboardView()
                .environment(store)
                .environment(tracker)
                .environment(sessionManager)
                .preferredColorScheme(store.configuration.appearance.colorScheme)
                .onAppear {
                    sessionManager.configure(store: store)
                    appDelegate.configure(sessionManager: sessionManager)
                    DockWindowController.shared.configure(store: store, tracker: tracker)
                }
                .onChange(of: store.configuration, initial: true) { _, configuration in
                    DockWindowController.shared.update(configuration: configuration)
                }
        }
        .defaultSize(width: 980, height: 680)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Volera Dock") {
                Button(store.configuration.isVisible ? "Hide Floating Dock" : "Show Floating Dock") {
                    DockWindowController.shared.toggleVisibility()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                .disabled(!sessionManager.isActive)

                if sessionManager.isActive {
                    Button("End Native Dock Session") {
                        sessionManager.stop { result in
                            if case .failure(let error) = result {
                                store.report(error.localizedDescription)
                            }
                        }
                    }
                }

                Button("Open Volera Dock Settings") {
                    DockWindowController.shared.openDashboard()
                }
                .keyboardShortcut(",", modifiers: .command)

                Divider()
                Button("Quit Volera Dock") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}

@MainActor
final class VoleraDockAppDelegate: NSObject, NSApplicationDelegate {
    private weak var sessionManager: NativeDockSessionManager?

    func configure() {
        NSApp.setActivationPolicy(.regular)
    }

    func configure(sessionManager: NativeDockSessionManager) {
        self.sessionManager = sessionManager
        configure()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let sessionManager, sessionManager.isActive else {
            DockWindowController.shared.close()
            return .terminateNow
        }
        sessionManager.stop { result in
            switch result {
            case .success:
                DockWindowController.shared.close()
                NSApp.reply(toApplicationShouldTerminate: true)
            case .failure:
                NSApp.reply(toApplicationShouldTerminate: false)
            }
        }
        return .terminateLater
    }

    func applicationWillTerminate(_ notification: Notification) {
        DockWindowController.shared.close()
    }
}

extension Notification.Name {
    static let voleraDockShowSettings = Notification.Name("dev.volera.dock.showSettings")
}
