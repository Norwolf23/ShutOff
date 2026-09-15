// Live Activity: the countdown on the lock screen and in the Dynamic Island.
import WidgetKit
import SwiftUI

@main
struct ShutOffWidgets: WidgetBundle {
    var body: some Widget { CountdownActivity() }
}

struct CountdownActivity: Widget {
    let night = Color(red: 0.03, green: 0.04, blue: 0.09)
    let text = Color(red: 0.902, green: 0.914, blue: 0.949)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CountdownAttributes.self) { ctx in
            HStack(spacing: 14) {
                Image(systemName: "moon").font(.system(size: 26, weight: .ultraLight))
                VStack(alignment: .leading, spacing: 2) {
                    Text("ShutOff").font(.system(size: 13, weight: .light)).tracking(1)
                    Text("until audio stops").font(.system(size: 11)).opacity(0.5)
                }
                Spacer()
                timer(ctx.state.end).font(.system(size: 30, weight: .ultraLight, design: .monospaced))
            }
            .padding(18)
            .foregroundStyle(text)
            .activityBackgroundTint(night)
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "moon").font(.system(size: 22, weight: .ultraLight)).padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timer(ctx.state.end).font(.system(size: 22, weight: .ultraLight, design: .monospaced)).padding(.trailing, 6)
                }
            } compactLeading: {
                Image(systemName: "moon")
            } compactTrailing: {
                timer(ctx.state.end).font(.system(size: 13, design: .monospaced)).frame(maxWidth: 56)
            } minimal: {
                Image(systemName: "moon")
            }
        }
    }

    // Counts down on its own; no ticking needed. Lower bound clamped so a stale activity can't crash.
    func timer(_ end: Date) -> some View {
        Text(timerInterval: min(.now, end)...end, countsDown: true)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}
