import Combine
import SwiftUI

struct StatusBarView: View {
    @Environment(SettingsStore.self) private var store
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            // Volera Branding
            HStack(spacing: 12) {
                // Temporary Brand Treatment (Programmatic Logo)
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [store.accentColor, store.accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "v.circle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("VOLERA")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .kerning(2.5)
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // System-style Indicators
            HStack(spacing: 24) {
                HStack(spacing: 16) {
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
                
                // Date & Time
                HStack(spacing: 16) {
                    Text(currentTime, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                    
                    Text(currentTime, format: .dateTime.hour().minute())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(.white.opacity(0.95))
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 44)
        .background(.ultraThinMaterial.opacity(0.5))
        .overlay(
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
            }
        )
        .onReceive(timer) { input in
            currentTime = input
        }
    }
}
