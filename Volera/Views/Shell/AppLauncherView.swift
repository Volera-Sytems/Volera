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
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 24) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    TextField("Search applications...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.title2)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(store.accentColor.opacity(0.5), lineWidth: 1)
                )
                .frame(maxWidth: 600)
                
                // Apps Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 20)], spacing: 24) {
                        ForEach(filteredApps) { app in
                            VStack(spacing: 8) {
                                if let nsImage = app.icon() {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                } else if let icon = app.iconName {
                                    Image(systemName: icon)
                                        .font(.system(size: 40))
                                        .frame(width: 80, height: 80)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 40))
                                        .frame(width: 80, height: 80)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                                
                                Text(app.name)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .foregroundStyle(.white)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.openShortcut(app)
                                withAnimation(.spring()) {
                                    isPresented = false
                                }
                            }
                        }
                    }
                    .padding(40)
                }
            }
            .padding(.top, 100)
            .padding(.horizontal, 40)
        }
        .onAppear {
            fetchApps()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
