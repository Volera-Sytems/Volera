import SwiftUI

struct DesktopShellView: View {
    @Environment(SettingsStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLauncherPresented = false
    @State private var showingSettings = false
    @State private var isAppActive = true
    
    var body: some View {
        ZStack {
            // 1. Background
            AmbientBackground(
                background: store.preferences.background,
                accent: store.accentColor,
                wallpaperImage: store.wallpaperImage,
                showsAtmosphere: isAppActive
            )
            .ignoresSafeArea()
            
            // 2. Desktop Workspace
            VStack(spacing: 0) {
                // Top margin for status bar
                Color.clear.frame(height: 48)
                
                Spacer()
                
                // Clock & Date (Restored)
                if store.preferences.showClock || store.preferences.showDate {
                    ClockPanel(
                        showClock: store.preferences.showClock,
                        showDate: store.preferences.showDate,
                        accent: store.accentColor
                    )
                    .padding(.bottom, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Desktop Icons (Favorites) - Improved spacing
                ScrollView(showsIndicators: false) {
                    FavoritesGrid(
                        shortcuts: store.preferences.shortcuts,
                        accent: store.accentColor,
                        onOpen: store.openShortcut,
                        onOpenSettings: { 
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingSettings = true 
                            }
                        }
                    )
                    .padding(.horizontal, 60)
                    .padding(.vertical, 20)
                }
                .frame(maxWidth: 1200)
                
                Spacer()
                
                // Bottom margin for dock
                Color.clear.frame(height: 100)
            }
            
            // 3. Status Bar
            VStack {
                StatusBarView()
                Spacer()
            }
            
            // 4. Dock
            VStack {
                Spacer()
                DockView(
                    pinnedApps: Array(store.preferences.shortcuts.prefix(8)), // Show more apps
                    onOpenLauncher: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isLauncherPresented.toggle()
                        }
                    },
                    onOpenSettings: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingSettings = true
                        }
                    }
                )
                .padding(.bottom, 24)
            }
            
            // 5. App Launcher Overlay
            if isLauncherPresented {
                AppLauncherView(isPresented: $isLauncherPresented)
                    .zIndex(100)
            }
            
            // 6. Settings Overlay
            if showingSettings {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture { 
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingSettings = false 
                            }
                        }
                    
                    SettingsView(store: store)
                        .frame(width: 850, height: 650)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: VoleraPalette.cardCornerRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 20)
                        .overlay(
                            Button(action: { 
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showingSettings = false 
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            .padding(24),
                            alignment: .topTrailing
                        )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(200)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .voleraToggleSettings)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingSettings = true
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            isAppActive = newPhase == .active
        }
    }
}
