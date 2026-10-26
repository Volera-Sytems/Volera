import AppKit
import SwiftUI

struct DockView: View {
    @Environment(SettingsStore.self) private var store
    let pinnedApps: [AppShortcut]
    var onOpenLauncher: () -> Void
    var onOpenSettings: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Launcher Button
            DockItem(icon: "square.grid.2x2.fill", label: "Launcher", accent: store.accentColor) {
                onOpenLauncher()
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 32)
                .padding(.horizontal, 4)
            
            ForEach(pinnedApps) { shortcut in
                DockItem(shortcut: shortcut, accent: store.accentColor) {
                    store.openShortcut(shortcut)
                }
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 32)
                .padding(.horizontal, 4)
            
            // Settings Button
            DockItem(icon: "gearshape.fill", label: "Settings", accent: store.accentColor) {
                onOpenSettings()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 15)
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
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 52, height: 52)
                        .transition(.scale.combined(with: .opacity))
                }
                
                VStack(spacing: 4) {
                    if let shortcut = shortcut {
                        if let nsImage = shortcut.icon() {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 42, height: 42)
                                .shadow(color: isHovering ? accent.opacity(0.3) : .clear, radius: 10)
                        } else {
                            Image(systemName: "app.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(isHovering ? accent : .white.opacity(0.9))
                        }
                    } else if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundStyle(isHovering ? accent : .white.opacity(0.9))
                    }
                }
                .frame(width: 52, height: 52)
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
