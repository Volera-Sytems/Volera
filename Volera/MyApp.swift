import AppKit
import SwiftUI

@main
struct MyApp: App {
    @State private var store = SettingsStore()

    var body: some Scene {
        WindowGroup {
            DesktopShellView()
                .environment(store)
                .preferredColorScheme(.dark)
                .onAppear {
                    configureWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }

    private func configureWindow() {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .black
            window.isMovableByWindowBackground = true
            
            // Persistent full-screen behavior
            window.collectionBehavior = [.fullScreenPrimary, .managed]
            
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
            
            // Prevent Escape from exiting full-screen
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // Escape key
                    NotificationCenter.default.post(name: .voleraToggleSettings, object: nil)
                    return nil // Consume the event
                }
                return event
            }
        }
    }
}

extension Notification.Name {
    static let voleraToggleSettings = Notification.Name("voleraToggleSettings")
}
