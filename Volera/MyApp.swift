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
            window.isMovableByWindowBackground = false
            
            // Shared-Space Desktop Architecture
            // Use a borderless window that fills the screen without native full-screen
            window.styleMask = [.borderless, .fullSizeContentView]
            window.collectionBehavior = [.managed]
            window.level = .normal // Stays in the managed Space
            
            // Size to the primary display
            updateWindowFrame(window)
            
            // Configure macOS presentation options to hide system UI while Volera is active
            NSApp.presentationOptions = [.autoHideDock, .autoHideMenuBar]
            
            // Update frame on screen changes
            NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { _ in
                self.updateWindowFrame(window)
            }
            
            // Contextual Escape handling
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // Escape key
                    NotificationCenter.default.post(name: .voleraEscapePressed, object: nil)
                    return nil // Consume the event
                }
                return event
            }
        }
    }
    
    private func updateWindowFrame(_ window: NSWindow) {
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true)
        }
    }
}

extension Notification.Name {
    static let voleraEscapePressed = Notification.Name("voleraEscapePressed")
}
