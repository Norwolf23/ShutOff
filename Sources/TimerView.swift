import SwiftUI

struct TimerView: View {
    @ObservedObject var model: Countdown
    @State private var customMinutes = 45

    var body: some View {
        GeometryReader { g in
            // ponytail: one scale factor for everything, 1 at the 300×500 minimum, capped at 2.
            let s = min(max(min(g.size.width / 300, g.size.height / 500), 1), 2)
            ZStack {
                NightSky()
                VStack(spacing: 0) {
                    header(s)
                    Spacer(minLength: 24 * s)
                    if let end = model.endDate { countdown(end, s) } else { picker(s) }
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
            Button { model.start(minutes: customMinutes) } label: {
                MoonView(phase: 0.62)
                    .frame(width: 150 * s)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12 * s)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start \(customMinutes) minutes")

            Text(Ender.promise)
                .font(.system(size: 13 * s, weight: .light))
                .foregroundStyle(Theme.dim)

            VStack(spacing: 0) {
                hrule
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            let m = presets[row * 3 + col]
                            Button(presetLabel(m)) { model.start(minutes: m) }
                                .buttonStyle(Key(s: s))
                                .accessibilityLabel("Start \(m) minutes")
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
                Button("−") { customMinutes = max(5, customMinutes - 5) }
                    .buttonStyle(Key(s: s, small: true))
                    .accessibilityLabel("5 minutes less")
                Text("\(customMinutes) min")
                    .font(.system(size: 13 * s, weight: .light, design: .monospaced))
                    .frame(width: 64 * s)
                Button("+") { customMinutes = min(480, customMinutes + 5) }
                    .buttonStyle(Key(s: s, small: true))
                    .accessibilityLabel("5 minutes more")
            }
            Button("Start \(customMinutes) min") { model.start(minutes: customMinutes) }
                .buttonStyle(Key(s: s, accent: true))
                .keyboardShortcut(.defaultAction)
                .overlay(alignment: .top) { hrule }
                .overlay(alignment: .bottom) { hrule }
        }
    }

    func countdown(_ end: Date, _ s: CGFloat) -> some View {
        VStack(spacing: 28 * s) {
            // Only the moon needs a clock; the digits count down on their own.
            // ponytail: no per-frame animation. A 1 s tween re-armed every second kept the blurred
            // Canvas re-rasterizing at 120 fps for the whole countdown (~15% CPU). One step a second is invisible.
            TimelineView(.periodic(from: .now, by: 1)) { tl in
                let p = model.progress(at: tl.date)
                MoonView(phase: 1 - p)
                    .frame(maxWidth: 180 * s)
            }
            VStack(spacing: 6 * s) {
                Text(timerInterval: min(.now, end)...end, countsDown: true)
                    .monospacedDigit()
                    .font(.system(size: 46 * s, weight: .ultraLight, design: .monospaced))
                Text(Ender.until)
                    .font(.system(size: 11 * s))
                    .foregroundStyle(Theme.dim)
            }

            HStack(spacing: 0) {
                Button("+10 min") { model.extend() }
                    .buttonStyle(Key(s: s))
                vrule
                Button("Cancel") { model.stop() }
                    .buttonStyle(Key(s: s))
                    .keyboardShortcut(.cancelAction)
            }
            .fixedSize(horizontal: false, vertical: true)
            .overlay(alignment: .top) { hrule }
            .overlay(alignment: .bottom) { hrule }
        }
    }

    var hrule: some View { Rectangle().fill(Theme.rule).frame(height: 1) }
    var vrule: some View { Rectangle().fill(Theme.rule).frame(width: 1) }
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
