import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum DashboardPage: String, CaseIterable, Identifiable {
    case home
    case applications
    case appearance
    case icons
    case position
    case behavior

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .home: "square.grid.2x2"
        case .applications: "dock.rectangle"
        case .appearance: "circle.lefthalf.filled"
        case .icons: "square.grid.3x3"
        case .position: "rectangle.bottomthird.inset.filled"
        case .behavior: "gearshape"
        }
    }
}

@MainActor
struct DockDashboardView: View {
    @Environment(DockStore.self) private var store
    @Environment(ApplicationTracker.self) private var tracker
    @Environment(\.openWindow) private var openWindow
    @State private var selection: DashboardPage? = .home

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Volera Dock") {
                    ForEach(DashboardPage.allCases) { page in
                        Label(page.title, systemImage: page.icon)
                            .tag(page)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(VoleraStyle.canvas)
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 260)
        } detail: {
            Group {
                switch selection ?? .home {
                case .home: WelcomePage(selection: $selection)
                case .applications: ApplicationsPage()
                case .appearance: AppearancePage()
                case .icons: IconBehaviorPage()
                case .position: PositionPage()
                case .behavior: BehaviorPage()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(VoleraStyle.canvas)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 620)
        .preferredColorScheme(store.configuration.appearance.colorScheme)
        .tint(VoleraStyle.blue)
        .onAppear {
            DockWindowController.shared.setOpenWindowAction { openWindow(id: "main") }
        }
        .onReceive(NotificationCenter.default.publisher(for: .voleraDockShowSettings)) { _ in
            selection = .applications
        }
    }
}

@MainActor
private struct WelcomePage: View {
    @Environment(DockStore.self) private var store
    @Environment(ApplicationTracker.self) private var tracker
    @Environment(NativeDockSessionManager.self) private var sessionManager
    @Binding var selection: DashboardPage?
    @State private var showingLaunchConsent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(VoleraStyle.blue)
                            Text("VOLERA DOCK")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .tracking(3)
                                .foregroundStyle(VoleraStyle.paleBlue)
                        }
                        Text("Your apps,\none reach away.")
                            .font(.system(size: 42, weight: .light, design: .rounded))
                            .tracking(-1.5)
                            .foregroundStyle(.white)
                        Text("A quiet, customizable floating dock that stays close while you work.")
                            .font(.system(size: 15))
                            .foregroundStyle(VoleraStyle.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 16)
                    Image(systemName: "sparkle")
                        .font(.system(size: 54, weight: .ultraLight))
                        .foregroundStyle(VoleraStyle.blue.opacity(0.7))
                        .padding(.top, 14)
                }

                dockPreview

                HStack(spacing: 12) {
                    Button {
                        if sessionManager.isActive {
                            sessionManager.stop { result in
                                if case .failure(let error) = result {
                                    store.report(error.localizedDescription)
                                }
                            }
                        } else {
                            showingLaunchConsent = true
                        }
                    } label: {
                        Label(
                            sessionManager.isActive ? "End Volera Session" : "LAUNCH",
                            systemImage: sessionManager.isActive ? "stop.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(sessionManager.isStarting || sessionManager.isStopping)

                    Button {
                        selection = .appearance
                    } label: {
                        Label("Customize", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Spacer()

                    Label(
                        sessionManager.isStarting
                            ? "Preparing session"
                            : (sessionManager.isActive
                                ? (store.configuration.isVisible ? "Dock is visible" : "Dock is hidden")
                                : "Session is not running"),
                        systemImage: sessionManager.isActive ? "circle.fill" : "circle"
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(sessionManager.isActive ? Color.green : VoleraStyle.muted)
                }

                HStack(spacing: 14) {
                    SummaryCard(
                        title: "Apps",
                        detail: "\(store.configuration.apps.count) pinned",
                        icon: "dock.rectangle"
                    ) {
                        selection = .applications
                    }
                    SummaryCard(
                        title: "Running",
                        detail: "\(tracker.runningApplications.count) active",
                        icon: "circle.dotted"
                    ) {
                        selection = .applications
                    }
                    SummaryCard(
                        title: "Placement",
                        detail: store.configuration.position.rawValue.capitalized,
                        icon: "rectangle.bottomthird.inset.filled"
                    ) {
                        selection = .position
                    }
                }

                if let error = store.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }

                HStack {
                    Text(store.statusMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(VoleraStyle.muted)
                    Spacer()
                    Button("Quit Volera Dock") {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(VoleraStyle.paleBlue)
                }
            }
            .padding(34)
        }
        .background {
            LinearGradient(
                colors: [VoleraStyle.panel.opacity(0.78), VoleraStyle.canvas],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .navigationTitle("Welcome")
        .alert("Launch Volera Dock?", isPresented: $showingLaunchConsent) {
            Button("Cancel", role: .cancel) {}
            Button("Continue to Volera") {
                sessionManager.start { result in
                    if case .failure(let error) = result {
                        store.report(error.localizedDescription)
                    }
                }
            }
        } message: {
            Text("Before launching, press Option-Command-D (⌥⌘D) to turn on macOS Dock auto-hide, then choose Continue to Volera. Volera does not change or save that preference and does not install a helper. macOS keeps your chosen setting until you press ⌥⌘D again. Volera also requests Dock auto-hide while it is active; that AppKit request does not control the Dock when another app is active.")
        }
    }

    private var dockPreview: some View {
        HStack(spacing: 14) {
            ForEach(store.configuration.apps.prefix(5)) { item in
                DockApplicationIcon(item: item, size: 38)
                    .frame(width: 48, height: 48)
            }
            if store.configuration.apps.isEmpty {
                ForEach(0..<4) { _ in
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.white.opacity(0.055))
                        .overlay {
                            Image(systemName: "app")
                                .font(.system(size: 18))
                                .foregroundStyle(VoleraStyle.paleBlue.opacity(0.32))
                        }
                        .frame(width: 48, height: 48)
                }
            }
            Capsule().fill(VoleraStyle.blue).frame(width: 12, height: 3)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .center)
        .background {
            RoundedRectangle(cornerRadius: store.configuration.cornerRadius, style: .continuous)
                .fill(Color(hex: store.configuration.backgroundHex).opacity(store.configuration.backgroundOpacity))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: store.configuration.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: store.configuration.cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
        }
        .padding(.vertical, 8)
        .accessibilityLabel("Live floating dock preview")
    }
}

private struct SummaryCard: View {
    let title: String
    let detail: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(VoleraStyle.blue)
                    .frame(width: 34, height: 34)
                    .background(VoleraStyle.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 12, weight: .semibold))
                    Text(detail).font(.system(size: 11)).foregroundStyle(VoleraStyle.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(VoleraStyle.muted)
            }
            .padding(14)
            .background(VoleraStyle.panel.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14).stroke(VoleraStyle.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

@MainActor
private struct ApplicationsPage: View {
    @Environment(DockStore.self) private var store
    @State private var isImporterPresented = false

    var body: some View {
        SettingsPageContainer(
            title: "Applications",
            subtitle: "Choose the apps that live in your floating dock. Drag icons in the dock to reorder them."
        ) {
            SettingsCard(title: "Dock applications", subtitle: "\(store.configuration.apps.count) pinned") {
                if store.configuration.apps.isEmpty {
                    ContentUnavailableView(
                        "Your dock is empty",
                        systemImage: "dock.rectangle",
                        description: Text("Add real Mac applications to launch them from the floating dock.")
                    )
                    .frame(minHeight: 150)
                } else {
                    ForEach(Array(store.configuration.apps.enumerated()), id: \.element.id) { index, item in
                        ApplicationSettingsRow(
                            item: item,
                            index: index,
                            count: store.configuration.apps.count,
                            move: move,
                            remove: { store.remove(item) }
                        )
                        if index < store.configuration.apps.count - 1 {
                            Divider().overlay(VoleraStyle.line)
                        }
                    }
                }

                Button {
                    isImporterPresented = true
                } label: {
                    Label("Add Applications", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            SettingsCard(title: "Running applications", subtitle: "Updated from macOS lifecycle notifications") {
                if store.configuration.apps.isEmpty {
                    Text("Add applications to see their running state here.")
                        .foregroundStyle(VoleraStyle.muted)
                } else {
                    ForEach(store.configuration.apps) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(statusColor(for: item))
                                .frame(width: 7, height: 7)
                            Text(item.name)
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Text(statusText(for: item))
                                .font(.system(size: 12))
                                .foregroundStyle(VoleraStyle.muted)
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.application],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls): store.addApplications(from: urls)
            case .failure(let error): store.report("Could not add applications: \(error.localizedDescription)")
            }
        }
    }

    @Environment(ApplicationTracker.self) private var tracker

    private func move(_ source: Int, _ offset: Int) {
        let destination = source + offset
        guard store.configuration.apps.indices.contains(destination) else { return }
        var apps = store.configuration.apps
        apps.swapAt(source, destination)
        store.configuration.apps = apps
    }

    private func statusColor(for item: DockAppItem) -> Color {
        tracker.application(for: item) == nil ? VoleraStyle.muted : .green
    }

    private func statusText(for item: DockAppItem) -> String {
        guard let app = tracker.application(for: item) else { return "Not running" }
        return app.bundleIdentifier == tracker.frontmostBundleIdentifier ? "Active" : "Running"
    }
}

private struct ApplicationSettingsRow: View {
    let item: DockAppItem
    let index: Int
    let count: Int
    let move: (Int, Int) -> Void
    let remove: () -> Void

    private var isAvailable: Bool {
        item.isAvailable()
    }

    var body: some View {
        HStack(spacing: 12) {
            DockApplicationIcon(item: item, size: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                Text(isAvailable ? (item.bundleIdentifier ?? item.path) : "Unavailable — moved or deleted")
                    .font(.system(size: 10))
                    .foregroundStyle(isAvailable ? VoleraStyle.muted : .orange)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button { move(index, -1) } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(index == 0)
            .help("Move earlier")
            Button { move(index, 1) } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(index == count - 1)
            .help("Move later")
            Button(role: .destructive, action: remove) {
                Image(systemName: "minus.circle")
            }
            .help("Remove application")
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 7)
    }
}

@MainActor
private struct AppearancePage: View {
    @Environment(DockStore.self) private var store

    var body: some View {
        SettingsPageContainer(
            title: "Appearance",
            subtitle: "Choose a starting look, then fine-tune the floating dock. Changes preview live."
        ) {
            SettingsCard(title: "Presets", subtitle: "Themes are real dock configurations and remain customizable") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(DockTheme.allCases.filter { $0 != .custom }) { theme in
                        Button {
                            store.configuration.apply(theme)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: theme.values.backgroundHex).opacity(theme.values.opacity))
                                    .frame(height: 52)
                                    .overlay {
                                        HStack(spacing: 6) {
                                            ForEach(0..<3) { _ in
                                                Circle().fill(Color.white.opacity(0.72)).frame(width: 14, height: 14)
                                            }
                                        }
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(store.configuration.theme == theme ? 0.55 : 0.08), lineWidth: 1)
                                    }
                                HStack {
                                    Text(theme.title).font(.system(size: 12, weight: .semibold))
                                    Spacer()
                                    if store.configuration.theme == theme {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(VoleraStyle.blue)
                                    }
                                }
                                .foregroundStyle(.white)
                            }
                            .padding(10)
                            .background(VoleraStyle.panel.opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            SettingsCard(title: "Surface", subtitle: "Material, tint, shape, and depth") {
                Picker("Appearance", selection: binding(\.appearance)) {
                    ForEach(DockAppearance.allCases) { appearance in
                        Text(appearance.rawValue.capitalized).tag(appearance)
                    }
                }
                ColorPicker("Dock background", selection: colorBinding)
                SettingSlider(title: "Background opacity", value: binding(\.backgroundOpacity), range: 0.25...1, format: .percent)
                SettingSlider(title: "Corner radius", value: binding(\.cornerRadius), range: 10...42, suffix: " pt")
                SettingSlider(title: "Shadow intensity", value: binding(\.shadowIntensity), range: 0...0.8, format: .percent)
                Toggle("Show outline", isOn: binding(\.showsBorder))
                    .tint(VoleraStyle.blue)
            }
        }
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: store.configuration.backgroundHex) },
            set: {
                store.configuration.backgroundHex = $0.rgbHex
                store.configuration.markCustom()
            }
        )
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<DockConfiguration, Value>) -> Binding<Value> {
        Binding(
            get: { store.configuration[keyPath: keyPath] },
            set: {
                store.configuration[keyPath: keyPath] = $0
                store.configuration.markCustom()
            }
        )
    }
}

@MainActor
private struct IconBehaviorPage: View {
    @Environment(DockStore.self) private var store

    var body: some View {
        SettingsPageContainer(
            title: "Icons & motion",
            subtitle: "Keep the dock legible and responsive, with restrained movement."
        ) {
            SettingsCard(title: "Icon layout", subtitle: "Size and spacing update the floating dock immediately") {
                SettingSlider(title: "Icon size", value: binding(\.iconSize), range: 32...84, suffix: " pt")
                SettingSlider(title: "Icon spacing", value: binding(\.iconSpacing), range: 2...28, suffix: " pt")
                SettingSlider(title: "Hover magnification", value: binding(\.hoverMagnification), range: 1...1.35, suffix: "×")
                SettingSlider(title: "Animation speed", value: binding(\.animationDuration), range: 0.08...0.5, suffix: " s")
            }

            SettingsCard(title: "Feedback", subtitle: "Show useful state without visual clutter") {
                Toggle("Show running and active indicators", isOn: binding(\.showsRunningIndicators))
                    .tint(VoleraStyle.blue)
                Toggle("Enable hover magnification and highlights", isOn: binding(\.showsHoverEffects))
                    .tint(VoleraStyle.blue)
                Text("Running state follows application launch, activation, and termination notifications from macOS. Apps with unusual launch behavior may not expose an individual running indicator.")
                    .font(.system(size: 11))
                    .foregroundStyle(VoleraStyle.muted)
            }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<DockConfiguration, Value>) -> Binding<Value> {
        Binding(
            get: { store.configuration[keyPath: keyPath] },
            set: {
                store.configuration[keyPath: keyPath] = $0
                store.configuration.markCustom()
            }
        )
    }
}

@MainActor
private struct PositionPage: View {
    @Environment(DockStore.self) private var store

    var body: some View {
        SettingsPageContainer(
            title: "Position",
            subtitle: "Place the dock along an edge of a selected display. Positioning stays within the display's usable area."
        ) {
            SettingsCard(title: "Screen edge", subtitle: "Side positions use a vertical icon layout") {
                Picker("Position", selection: binding(\.position)) {
                    ForEach(DockPosition.allCases) { position in
                        Text(position.rawValue.capitalized).tag(position)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Display", selection: displayBinding) {
                    Text("Main Display").tag("main")
                    ForEach(displays, id: \.id) { display in
                        Text(display.name).tag(display.id)
                    }
                }

                SettingSlider(title: "Edge offset", value: binding(\.edgeOffset), range: 0...100, suffix: " pt")
            }

            SettingsCard(title: "Space behavior", subtitle: "Best-effort native floating window behavior") {
                Label("The dock is configured to join Spaces and to act as a full-screen auxiliary panel.", systemImage: "rectangle.on.rectangle")
                    .font(.system(size: 13))
                Text("macOS controls Spaces. Full-screen apps, secure windows, or system transitions may still cover or hide a floating utility window. Launching Volera Dock can opt into system-wide native Dock auto-hide; the native Dock is never disabled and may still be revealed by macOS.")
                    .font(.system(size: 11))
                    .foregroundStyle(VoleraStyle.muted)
            }
        }
    }

    private var displays: [(id: String, name: String)] {
        NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            return (number.stringValue, screen.localizedName)
        }
    }

    private var displayBinding: Binding<String> {
        Binding(
            get: { store.configuration.selectedDisplayID ?? "main" },
            set: { store.configuration.selectedDisplayID = $0 == "main" ? nil : $0 }
        )
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<DockConfiguration, Value>) -> Binding<Value> {
        Binding(
            get: { store.configuration[keyPath: keyPath] },
            set: { store.configuration[keyPath: keyPath] = $0 }
        )
    }
}

@MainActor
private struct BehaviorPage: View {
    @Environment(DockStore.self) private var store

    var body: some View {
        SettingsPageContainer(
            title: "Behavior",
            subtitle: "Control visibility and how Volera Dock fits into your Mac session."
        ) {
            SettingsCard(title: "Floating dock", subtitle: "The settings window and floating dock are independent") {
                Toggle(
                    store.configuration.isVisible ? "Dock is visible" : "Dock is hidden",
                    isOn: binding(\.isVisible)
                )
                .tint(VoleraStyle.blue)

                Toggle(
                    "Open Volera Dock at login",
                    isOn: Binding(
                        get: { store.configuration.launchesAtLogin },
                        set: { store.setLaunchAtLogin($0) }
                    )
                )
                .tint(VoleraStyle.blue)

                Text("Login startup is registered with macOS Service Management. macOS may require approval in System Settings > General > Login Items. This feature does not require Accessibility permission.")
                    .font(.system(size: 11))
                    .foregroundStyle(VoleraStyle.muted)
            }

            SettingsCard(title: "Recovery", subtitle: "Volera Dock makes no global Dock or menu-bar preference changes") {
                Button("Restore default appearance and behavior") {
                    store.restoreDefaults()
                }
                .buttonStyle(.bordered)

                Button("Quit Volera Dock") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Text("Quitting closes the floating panel. Closing this settings window leaves the dock running; reopen Volera Dock from the macOS Dock to manage it.")
                    .font(.system(size: 11))
                    .foregroundStyle(VoleraStyle.muted)
            }

            if let error = store.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 12))
            }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<DockConfiguration, Value>) -> Binding<Value> {
        Binding(
            get: { store.configuration[keyPath: keyPath] },
            set: { store.configuration[keyPath: keyPath] = $0 }
        )
    }
}

private struct SettingsPageContainer<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(VoleraStyle.muted)
                }
                .padding(.bottom, 6)

                content
            }
            .padding(28)
        }
        .background(VoleraStyle.canvas)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(VoleraStyle.muted)
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VoleraStyle.panel.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(VoleraStyle.line, lineWidth: 1)
        }
    }
}

private struct SettingSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var suffix = ""
    var format: ValueFormat = .decimal

    enum ValueFormat {
        case decimal
        case percent
    }

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(title).font(.system(size: 12))
                Spacer()
                Text(formattedValue)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(VoleraStyle.muted)
            }
            Slider(value: $value, in: range)
                .tint(VoleraStyle.blue)
        }
    }

    private var formattedValue: String {
        switch format {
        case .decimal: "\(value.formatted(.number.precision(.fractionLength(0...2))))\(suffix)"
        case .percent: value.formatted(.percent.precision(.fractionLength(0)))
        }
    }
}
