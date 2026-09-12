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
        ZStack {
            NightSky()
            VStack(spacing: 0) {
                header
                Spacer(minLength: 24)
                if endDate == nil { picker } else { countdown }
                Spacer(minLength: 24)
            }
            .padding(28)
            .frame(maxWidth: 360)
        }
        #if os(macOS)
        .frame(width: 300, height: 500)
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

    var header: some View {
        HStack {
            Text("ShutOff")
                .font(.system(size: 15, weight: .light))
                .tracking(1.5)
            Spacer()
        }
    }

    var picker: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "moon")
                .font(.system(size: 88, weight: .ultraLight))
                .foregroundStyle(Theme.moon)
                .shadow(color: Theme.moon.opacity(0.45), radius: 18)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
            Text(Ender.promise)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Theme.dim)

            VStack(spacing: 0) {
                hrule
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            let m = presets[row * 3 + col]
                            Button(label(m)) { start(minutes: m) }
                                .buttonStyle(Key())
                            if col < 2 { vrule }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    hrule
                }
            }

            HStack(spacing: 0) {
                Text("Custom").font(.system(size: 13, weight: .light)).foregroundStyle(Theme.dim)
                Spacer()
                Button("−") { customMinutes = max(5, customMinutes - 5) }.buttonStyle(Key(small: true))
                Text("\(customMinutes) min")
                    .font(.system(size: 13, weight: .light, design: .monospaced))
                    .frame(width: 64)
                Button("+") { customMinutes = min(480, customMinutes + 5) }.buttonStyle(Key(small: true))
            }
            Button("Start \(customMinutes) min") { start(minutes: customMinutes) }
                .buttonStyle(Key(accent: true))
                .overlay(alignment: .top) { hrule }
                .overlay(alignment: .bottom) { hrule }
        }
    }

    var countdown: some View {
        VStack(spacing: 28) {
            MoonView(phase: 1 - progress)
                .frame(maxWidth: 180)
                .animation(.linear(duration: 0.5), value: progress)
            VStack(spacing: 6) {
                Text(timeString)
                    .font(.system(size: 46, weight: .ultraLight, design: .monospaced))
                Text(Ender.until)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
            }

            HStack(spacing: 0) {
                Button("+10 min") {
                    endDate = endDate?.addingTimeInterval(600)
                    total += 600
                }
                .buttonStyle(Key())
                vrule
                Button("Cancel") { stop() }
                    .buttonStyle(Key())
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
    var accent = false
    var small = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: small ? 16 : 14, weight: .light, design: .monospaced))
            .foregroundStyle(configuration.isPressed || accent ? Theme.moon : Theme.text)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .frame(maxWidth: small ? nil : .infinity)
            .frame(minWidth: small ? 36 : nil)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
    }
}
