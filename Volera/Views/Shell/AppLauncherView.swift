import AppKit
import SwiftUI

struct AppLauncherView: View {
    @Environment(SettingsStore.self) private var store
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    // In a real implementation, we would fetch apps from /Applications
    @State private var apps: [AppShortcut] = []
    
    func fetchApps() {
        let fileManager = FileManager.default
        let appDirs = ["/Applications", "/System/Applications"]
        var foundApps: [AppShortcut] = []
        
        for dir in appDirs {
            let url = URL(fileURLWithPath: dir)
            if let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                for appURL in contents where appURL.pathExtension == "app" {
                    if let shortcut = AppShortcut(url: appURL) {
                        foundApps.append(shortcut)
                    }
                }
            }
        }
        
        // Add existing shortcuts if not already there
        for shortcut in store.preferences.shortcuts {
            if !foundApps.contains(where: { $0.bundleIdentifier == shortcut.bundleIdentifier }) {
                foundApps.append(shortcut)
            }
        }
        
        self.apps = foundApps.sorted(by: { $0.name < $1.name })
    }
    
    var filteredApps: [AppShortcut] {
        if searchText.isEmpty {
            return apps
        }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 32) {
                // Search Bar
                HStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                        .foregroundStyle(store.accentColor)
                    
                    TextField("Search applications...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.title2)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(.ultraThinMaterial.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .frame(maxWidth: 700)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Apps Grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 140), spacing: 32)], spacing: 40) {
                        ForEach(filteredApps) { app in
                            AppLauncherItem(app: app, accent: store.accentColor) {
                                store.openShortcut(app)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                            }
                        }
                    }
                    .padding(60)
                }
            }
            .padding(.top, 120)
            .padding(.horizontal, 60)
        }
        .onAppear {
            fetchApps()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}

struct AppLauncherItem: View {
    let app: AppShortcut
    let accent: Color
    var action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let nsImage = app.icon() {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .padding(12)
                        .background(.ultraThinMaterial.opacity(isHovering ? 0.3 : 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: isHovering ? accent.opacity(0.3) : .clear, radius: 15)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 48))
                        .frame(width: 96, height: 96)
                        .background(.ultraThinMaterial.opacity(isHovering ? 0.3 : 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .foregroundStyle(isHovering ? accent : .white.opacity(0.8))
                }
                
                Text(app.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundStyle(isHovering ? .white : .white.opacity(0.8))
                    .frame(height: 32, alignment: .top)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .scaleEffect(isHovering ? 1.1 : 1.0)
    }
}
