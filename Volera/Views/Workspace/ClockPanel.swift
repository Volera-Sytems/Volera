import SwiftUI

struct ClockPanel: View {
    let showClock: Bool
    let showDate: Bool
    let accent: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 10) {
                if showClock {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(context.date, format: Date.FormatStyle().hour().minute())
                            .font(.system(size: 84, weight: .ultraLight, design: .rounded))
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.94))
                            .monospacedDigit()

                        Text(secondText(for: context.date))
                            .font(.system(size: 28, weight: .light, design: .rounded))
                            .foregroundStyle(accent.opacity(0.9))
                            .monospacedDigit()
                    }
                    .shadow(color: .black.opacity(0.45), radius: 18, y: 4)
                    .shadow(color: accent.opacity(0.22), radius: 24, y: 6)
                }

                if showDate {
                    Text(context.date, format: Date.FormatStyle().weekday(.wide).month(.wide).day())
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundStyle(VoleraPalette.mist)
                        .tracking(1.6)
                        .shadow(color: .black.opacity(0.45), radius: 10, y: 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
    }

    private func secondText(for date: Date) -> String {
        String(format: "%02d", Calendar.current.component(.second, from: date))
    }
}

#Preview {
    ClockPanel(showClock: true, showDate: true, accent: VoleraPalette.icyBlue)
        .padding(40)
        .background(VoleraPalette.charcoal)
}
