import SwiftUI

let presets = [15, 30, 45, 60, 90, 120]

struct TimerView: View {
    @State private var endDate: Date?
    @State private var total: TimeInterval = 1
    @State private var customMinutes = 45
    @State private var now = Date()
    private let ender = Ender()
    private let tick = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { g in
            // ponytail: one scale factor for everything, 1 at the 300×500 minimum, capped at 2.
            let s = min(max(min(g.size.width / 300, g.size.height / 500), 1), 2)
            ZStack {
                NightSky()
                VStack(spacing: 0) {
                    header(s)
                    Spacer(minLength: 24 * s)
                    if endDate == nil { picker(s) } else { countdown(s) }
                    Spacer(minLength: 24 * s)
                }
                .padding(28 * s)
                .frame(maxWidth: 360 * s)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        #if os(macOS)
        .frame(minWidth: 300, minHeight: 500)
        #endif
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
        .onReceive(tick) { t in
            now = t
            if let end = endDate, t >= end {
                endDate = nil
                ender.fire()
            }
        }
    }

    func header(_ s: CGFloat) -> some View {
        HStack {
            Text("ShutOff")
                .font(.system(size: 15 * s, weight: .light))
                .tracking(1.5 * s)
            Spacer()
        }
    }

    func picker(_ s: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 20 * s) {
            Button { start(minutes: customMinutes) } label: {
                MoonView(phase: 0.62)
                    .frame(width: 150 * s)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12 * s)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(Ender.promise)
                .font(.system(size: 13 * s, weight: .light))
                .foregroundStyle(Theme.dim)

            VStack(spacing: 0) {
                hrule
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            let m = presets[row * 3 + col]
                            Button(label(m)) { start(minutes: m) }
                                .buttonStyle(Key(s: s))
                            if col < 2 { vrule }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    hrule
                }
            }

            HStack(spacing: 0) {
                Text("Custom").font(.system(size: 13 * s, weight: .light)).foregroundStyle(Theme.dim)
                Spacer()
                Button("−") { customMinutes = max(5, customMinutes - 5) }.buttonStyle(Key(s: s, small: true))
                Text("\(customMinutes) min")
                    .font(.system(size: 13 * s, weight: .light, design: .monospaced))
                    .frame(width: 64 * s)
                Button("+") { customMinutes = min(480, customMinutes + 5) }.buttonStyle(Key(s: s, small: true))
            }
            Button("Start \(customMinutes) min") { start(minutes: customMinutes) }
                .buttonStyle(Key(s: s, accent: true))
                .overlay(alignment: .top) { hrule }
                .overlay(alignment: .bottom) { hrule }
        }
    }

    func countdown(_ s: CGFloat) -> some View {
        VStack(spacing: 28 * s) {
            MoonView(phase: 1 - progress)
                .frame(maxWidth: 180 * s)
                .animation(.linear(duration: 0.5), value: progress)
            VStack(spacing: 6 * s) {
                Text(timeString)
                    .font(.system(size: 46 * s, weight: .ultraLight, design: .monospaced))
                Text(Ender.until)
                    .font(.system(size: 11 * s))
                    .foregroundStyle(Theme.dim)
            }

            HStack(spacing: 0) {
                Button("+10 min") {
                    endDate = endDate?.addingTimeInterval(600)
                    total += 600
                }
                .buttonStyle(Key(s: s))
                vrule
                Button("Cancel") { stop() }
                    .buttonStyle(Key(s: s))
            }
            .fixedSize(horizontal: false, vertical: true)
            .overlay(alignment: .top) { hrule }
            .overlay(alignment: .bottom) { hrule }
        }
    }

    var hrule: some View { Rectangle().fill(Theme.rule).frame(height: 1) }
    var vrule: some View { Rectangle().fill(Theme.rule).frame(width: 1) }

    var remaining: TimeInterval { max(0, endDate?.timeIntervalSince(now) ?? 0) }
    var progress: Double { total > 0 ? remaining / total : 0 }

    var timeString: String {
        let r = Int(remaining.rounded())
        let h = r / 3600, m = (r % 3600) / 60, s = r % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    func label(_ m: Int) -> String {
        m < 60 ? "\(m)m" : m % 60 == 0 ? "\(m / 60)h" : String(format: "%gh", Double(m) / 60)
    }

    func start(minutes: Int) {
        total = TimeInterval(minutes * 60)
        endDate = Date().addingTimeInterval(total)
        ender.begin()
    }

    func stop() {
        endDate = nil
        ender.cancel()
    }
}

/// Plain text key: no fill, no border. Dividers come from the parent.
struct Key: ButtonStyle {
    var s: CGFloat = 1
    var accent = false
    var small = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: (small ? 16 : 14) * s, weight: .light, design: .monospaced))
            .foregroundStyle(configuration.isPressed || accent ? Theme.moon : Theme.text)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .frame(maxWidth: small ? nil : .infinity)
            .frame(minWidth: small ? 36 * s : nil)
            .padding(.vertical, 13 * s)
            .contentShape(Rectangle())
    }
}
