import AppKit
import SwiftUI

struct DockView: View {
    @Environment(SettingsStore.self) private var store
    let pinnedApps: [AppShortcut]
    var onOpenLauncher: () -> Void
    var onOpenSettings: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Launcher Button
            DockItem(icon: "square.grid.2x2.fill", label: "Launcher", accent: store.accentColor) {
                onOpenLauncher()
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 36)
                .padding(.horizontal, 6)
            
            ForEach(pinnedApps) { shortcut in
                DockItem(shortcut: shortcut, accent: store.accentColor) {
                    store.openShortcut(shortcut)
                }
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 36)
                .padding(.horizontal, 6)
            
            // Settings Button
            DockItem(icon: "gearshape.fill", label: "Settings", accent: store.accentColor) {
                onOpenSettings()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius + 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius + 4, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.45), radius: 30, x: 0, y: 18)
    }
}

struct DockItem: View {
    let shortcut: AppShortcut?
    let icon: String?
    let label: String
    let accent: Color
    var action: () -> Void
    
    @State private var isHovering = false
    
    init(shortcut: AppShortcut, accent: Color, action: @escaping () -> Void) {
        self.shortcut = shortcut
        self.icon = nil
        self.label = shortcut.name
        self.accent = accent
        self.action = action
    }
    
    init(icon: String, label: String, accent: Color, action: @escaping () -> Void) {
        self.shortcut = nil
        self.icon = icon
        self.label = label
        self.accent = accent
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isHovering {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 64, height: 64)
                        .transition(.scale.combined(with: .opacity))
                }
                
                VStack(spacing: 4) {
                    if let shortcut = shortcut {
                        if let nsImage = shortcut.icon() {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                                .shadow(color: isHovering ? accent.opacity(0.35) : .clear, radius: 12)
                        } else {
                            Image(systemName: "app.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(isHovering ? accent : .white.opacity(0.95))
                        }
                    } else if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundStyle(isHovering ? accent : .white.opacity(0.95))
                    }
                }
                .frame(width: 64, height: 64)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .scaleEffect(isHovering ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
    }
}
