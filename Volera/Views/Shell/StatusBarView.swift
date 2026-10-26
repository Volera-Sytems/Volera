import Combine
import SwiftUI

struct StatusBarView: View {
    @Environment(SettingsStore.self) private var store
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            // Volera Branding
            HStack(spacing: 10) {
                // Temporary Brand Treatment (Programmatic Logo)
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [store.accentColor, store.accentColor.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: "v.circle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("VOLERA")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .kerning(2.0)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // System-style Indicators
            HStack(spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
                
                // Date & Time
                HStack(spacing: 12) {
                    Text(currentTime, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                    
                    Text(currentTime, format: .dateTime.hour().minute())
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 36)
        .background(.ultraThinMaterial.opacity(0.5))
        .overlay(
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 0.5)
            }
        )
        .onReceive(timer) { input in
            currentTime = input
        }
    }
}
