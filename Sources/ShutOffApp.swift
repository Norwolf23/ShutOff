import SwiftUI

@main
struct ShutOffApp: App {
    @StateObject private var model = Countdown.shared

    var body: some Scene {
        #if os(macOS)
        // One window, not a group: Cmd+N can't spawn a second timer, and closing it keeps the countdown alive.
        Window("ShutOff", id: "main") { TimerView(model: model) }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentMinSize)
            .defaultSize(width: 300, height: 500)
        MenuBarExtra { MenuBarMenu(model: model) } label: { MenuBarLabel(model: model) }
        #else
        WindowGroup { TimerView(model: model) }
        #endif
    }
}

#if os(macOS)
struct MenuBarLabel: View {
    @ObservedObject var model: Countdown
    var body: some View {
        if model.endDate != nil {
            Label { Text(clock(model.remaining)).monospacedDigit() }
                icon: { Image(systemName: "moon.fill") }
                .labelStyle(.titleAndIcon)
        } else {
            Image(systemName: "moon")
        }
    }
}

/// h:mm:ss or m:ss. Plain text on purpose: Text(timerInterval:) inside a MenuBarExtra label
/// re-renders the status item forever (100% CPU, +200 MB/s) on macOS 26.
func clock(_ s: TimeInterval) -> String {
    Duration.seconds(s).formatted(.time(pattern: s >= 3600 ? .hourMinuteSecond : .minuteSecond))
}

struct MenuBarMenu: View {
    @ObservedObject var model: Countdown
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        if let end = model.endDate {
            Text("Sleep at \(end, style: .time)")
            Button("+10 min") { model.extend() }
            Button("Cancel") { model.stop() }
        } else {
            ForEach(presets, id: \.self) { m in
                Button("Sleep in \(presetLabel(m))") { model.start(minutes: m) }
            }
        }
        Divider()
        Button("Open ShutOff") { openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true) }
        Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
#endif

enum Theme {
    static let night = [Color(red: 0.055, green: 0.070, blue: 0.135),   // #0E1222 top
                        Color(red: 0.016, green: 0.020, blue: 0.047)]   // #040510 bottom
    static let text  = Color(red: 0.902, green: 0.914, blue: 0.949)     // #E6E9F2 moonlight
    static let moon  = Color(red: 0.788, green: 0.831, blue: 0.918)     // #C9D4EA pale silver-blue
    static let dim   = text.opacity(0.42)
    static let rule  = Color.white.opacity(0.09)
}

/// Deep night gradient with a handful of faint stars. No illustration, just depth.
struct NightSky: View {
    // ponytail: fixed star field, fractions of the frame. Tweak here, not in code.
    static let stars: [(x: CGFloat, y: CGFloat, r: CGFloat, a: Double)] = [
        (0.12, 0.08, 1.2, 0.55), (0.82, 0.05, 0.9, 0.40), (0.68, 0.14, 1.4, 0.30),
        (0.30, 0.22, 0.8, 0.35), (0.92, 0.30, 1.1, 0.25), (0.06, 0.46, 0.9, 0.30),
        (0.55, 0.52, 0.7, 0.20), (0.88, 0.70, 1.0, 0.22), (0.20, 0.86, 0.8, 0.18),
    ]
    var body: some View {
        LinearGradient(colors: Theme.night, startPoint: .top, endPoint: .bottom)
            .overlay {
                Canvas { ctx, size in
                    for s in Self.stars {
                        let rect = CGRect(x: s.x * size.width - s.r, y: s.y * size.height - s.r, width: 2 * s.r, height: 2 * s.r)
                        ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(s.a)))
                    }
                }
            }
            .ignoresSafeArea()
    }
}
