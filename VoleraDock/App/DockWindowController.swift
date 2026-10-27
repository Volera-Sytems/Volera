import AppKit
import SwiftUI

@MainActor
final class DockWindowController {
    static let shared = DockWindowController()

    private var panel: NSPanel?
    private var store: DockStore?
    private var tracker: ApplicationTracker?
    private var sessionIsActive = false
    private var openWindowAction: (() -> Void)?
    private var observerTokens: [NSObjectProtocol] = []

    private init() {
        let center = NotificationCenter.default
        observerTokens.append(
            center.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.refreshPosition() }
            }
        )
        observerTokens.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.refreshPosition() }
            }
        )
    }

    isolated deinit {
        for token in observerTokens {
            NotificationCenter.default.removeObserver(token)
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
    }

    func configure(store: DockStore, tracker: ApplicationTracker) {
        self.store = store
        self.tracker = tracker
        update(configuration: store.configuration)
    }

    func setOpenWindowAction(_ action: @escaping () -> Void) {
        openWindowAction = action
    }

    func update(configuration: DockConfiguration) {
        guard let store, let tracker else { return }
        guard sessionIsActive, configuration.isVisible else {
            panel?.orderOut(nil)
            return
        }

        let dockPanel = panel ?? makePanel(store: store, tracker: tracker)
        panel = dockPanel
        refreshPosition(for: configuration)
        dockPanel.orderFrontRegardless()
    }

    func toggleVisibility() {
        guard sessionIsActive, let store else { return }
        store.configuration.isVisible.toggle()
    }

    func beginSession() {
        sessionIsActive = true
        store?.configuration.isVisible = true
        if let store {
            update(configuration: store.configuration)
        }
    }

    func endSession() {
        sessionIsActive = false
        store?.configuration.isVisible = false
        close()
    }

    func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where !(window is NSPanel) {
            window.makeKeyAndOrderFront(nil)
            NotificationCenter.default.post(name: .voleraDockShowSettings, object: nil)
            return
        }
        openWindowAction?()
        NotificationCenter.default.post(name: .voleraDockShowSettings, object: nil)
    }

    func close() {
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
    }

    private func makePanel(store: DockStore, tracker: ApplicationTracker) -> NSPanel {
        let panel = FloatingDockPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(
            rootView: FloatingDockView()
                .environment(store)
                .environment(tracker)
        )
        return panel
    }

    private func refreshPosition() {
        guard let store else { return }
        refreshPosition(for: store.configuration)
    }

    private func refreshPosition(for configuration: DockConfiguration) {
        guard let panel else { return }
        let screen = selectedScreen(for: configuration) ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }

        let itemCount = CGFloat(max(configuration.apps.count, 1))
        let iconSize = CGFloat(configuration.iconSize)
        let spacing = CGFloat(configuration.iconSpacing)
        let crossAxisSize = configuration.position == .bottom ? iconSize + 44 : iconSize + 116
        let idealPrimaryAxisSize = configuration.apps.isEmpty
            ? 280
            : itemCount * (iconSize + 10) +
                max(itemCount - 1, 0) * spacing +
                (configuration.position == .bottom ? 100 : 82)

        let size: NSSize
        switch configuration.position {
        case .bottom:
            size = NSSize(width: min(idealPrimaryAxisSize, max(120, screen.visibleFrame.width - 24)), height: crossAxisSize)
        case .left, .right:
            size = NSSize(width: crossAxisSize, height: min(idealPrimaryAxisSize, max(120, screen.visibleFrame.height - 24)))
        }

        let visibleFrame = screen.visibleFrame
        var origin: NSPoint
        switch configuration.position {
        case .bottom:
            origin = NSPoint(
                x: visibleFrame.midX - size.width / 2,
                y: visibleFrame.minY + configuration.edgeOffset
            )
        case .left:
            origin = NSPoint(
                x: visibleFrame.minX + configuration.edgeOffset,
                y: visibleFrame.midY - size.height / 2
            )
        case .right:
            origin = NSPoint(
                x: visibleFrame.maxX - size.width - configuration.edgeOffset,
                y: visibleFrame.midY - size.height / 2
            )
        }
        origin.x = min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - size.width)
        origin.y = min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - size.height)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.setContentSize(size)
    }

    private func selectedScreen(for configuration: DockConfiguration) -> NSScreen? {
        guard let selectedDisplayID = configuration.selectedDisplayID else { return NSScreen.main }
        return NSScreen.screens.first { screen in
            guard let displayNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return displayNumber.stringValue == selectedDisplayID
        } ?? NSScreen.main
    }
}

private final class FloatingDockPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
