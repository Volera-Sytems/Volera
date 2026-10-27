import AppKit
import SwiftUI

@MainActor
struct FloatingDockView: View {
    @Environment(DockStore.self) private var store
    @Environment(ApplicationTracker.self) private var tracker

    private var configuration: DockConfiguration { store.configuration }
    private var isVertical: Bool { configuration.position != .bottom }
    private var dockPrimaryAxisSize: CGFloat {
        guard !configuration.apps.isEmpty else { return 280 }
        let itemCount = CGFloat(configuration.apps.count)
        let iconSize = CGFloat(configuration.iconSize)
        let spacing = CGFloat(configuration.iconSpacing)
        return itemCount * (iconSize + 10) +
            max(itemCount - 1, 0) * spacing +
            (isVertical ? 82 : 100)
    }

    var body: some View {
        ScrollView(isVertical ? .vertical : .horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if isVertical {
                    VStack(spacing: configuration.iconSpacing) {
                        appItems
                        if configuration.apps.isEmpty {
                            emptyState
                        }
                    }
                } else {
                    HStack(spacing: configuration.iconSpacing) {
                        appItems
                        if configuration.apps.isEmpty {
                            emptyState
                        }
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: isVertical ? 28 : 1, height: isVertical ? 1 : 34)
                    .padding(isVertical ? .vertical : .horizontal, 4)

                Button {
                    DockWindowController.shared.openDashboard()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(VoleraStyle.paleBlue.opacity(0.88))
                        .frame(width: 38, height: 38)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Manage Volera Dock applications")
            }
        }
        .scrollClipDisabled()
        .padding(isVertical ? 12 : 14)
        .background {
            RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous)
                .fill(Color(hex: configuration.backgroundHex).opacity(configuration.backgroundOpacity))
                .background(.ultraThinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous))
                .overlay {
                    if configuration.showsBorder {
                        RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    }
                }
                .shadow(
                    color: .black.opacity(configuration.shadowIntensity),
                    radius: 26,
                    x: 0,
                    y: 12
                )
        }
        .preferredColorScheme(configuration.appearance.colorScheme)
        .frame(
            width: isVertical ? configuration.iconSize + 116 : dockPrimaryAxisSize,
            height: isVertical ? dockPrimaryAxisSize : configuration.iconSize + 44
        )
        .animation(.easeOut(duration: configuration.animationDuration), value: configuration.apps)
        .animation(.easeOut(duration: configuration.animationDuration), value: configuration.position)
    }

    @ViewBuilder
    private var appItems: some View {
        ForEach(configuration.apps) { item in
            DockAppButton(
                item: item,
                iconSize: configuration.iconSize,
                magnification: configuration.hoverMagnification,
                animationDuration: configuration.animationDuration,
                showsHoverEffects: configuration.showsHoverEffects,
                isRunning: tracker.application(for: item) != nil,
                isActive: tracker.frontmostBundleIdentifier == item.bundleIdentifier,
                showsRunningIndicators: configuration.showsRunningIndicators,
                isVertical: isVertical
            ) {
                if let runningApplication = tracker.application(for: item) {
                    store.activate(runningApplication, named: item.name)
                } else {
                    store.launch(item, tracker: tracker)
                }
            }
            .draggable(item.id.uuidString)
            .dropDestination(for: String.self) { identifiers, _ in
                guard let identifier = identifiers.first else { return false }
                store.move(identifier, before: item.id.uuidString)
                return true
            }
            .contextMenu {
                if let application = tracker.application(for: item) {
                    Button("Activate \(item.name)") {
                        store.activate(application, named: item.name)
                    }
                } else {
                    Button("Open \(item.name)") {
                        store.launch(item, tracker: tracker)
                    }
                }
                Divider()
                Button("Remove from Dock", role: .destructive) {
                    store.remove(item)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .medium))
            Text("Add apps in Volera Dock")
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundStyle(VoleraStyle.paleBlue.opacity(0.82))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

@MainActor
private struct DockAppButton: View {
    let item: DockAppItem
    let iconSize: Double
    let magnification: Double
    let animationDuration: Double
    let showsHoverEffects: Bool
    let isRunning: Bool
    let isActive: Bool
    let showsRunningIndicators: Bool
    let isVertical: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                DockApplicationIcon(item: item, size: iconSize)
                    .scaleEffect(showsHoverEffects && isHovered ? magnification : 1)
                    .shadow(
                        color: isHovered ? VoleraStyle.blue.opacity(0.22) : .clear,
                        radius: 14,
                        y: 4
                    )

                if showsRunningIndicators && isRunning {
                    Capsule()
                        .fill(isActive ? VoleraStyle.blue : Color.white.opacity(0.66))
                        .frame(width: isActive ? 13 : 5, height: 3)
                }
            }
            .frame(width: iconSize + 10, height: iconSize + 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.spring(response: animationDuration, dampingFraction: 0.74), value: isHovered)
        .help(item.name)
        .accessibilityLabel("Open \(item.name)")
    }
}
