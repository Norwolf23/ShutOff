import SwiftUI

@main
struct ShutOffApp: App {
    var body: some Scene {
        WindowGroup {
            TimerView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 300, height: 500)
        #endif
    }
}

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
