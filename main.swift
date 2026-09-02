import SwiftUI
import IOKit.pwr_mgt

@main
struct ShutOffApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

let presets = [15, 30, 45, 60, 90, 120]

struct ContentView: View {
    @State private var endDate: Date?
    @State private var total: TimeInterval = 1
    @State private var customMinutes = 45
    @State private var activity: NSObjectProtocol?
    @State private var now = Date()

    private let tick = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.08, blue: 0.24), Color(red: 0.01, green: 0.01, blue: 0.05)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if endDate == nil { picker } else { countdown }
        }
        .frame(width: 300, height: 430)
        .preferredColorScheme(.dark)
        .onReceive(tick) { t in
            now = t
            if let end = endDate, t >= end {
                stop()
                sleepMac()
            }
        }
    }

    var picker: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color(red: 1.0, green: 0.9, blue: 0.7))
            Text("ShutOff")
                .font(.system(.title, design: .rounded).weight(.semibold))
            Text("Sleep this Mac after…")
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(presets, id: \.self) { m in
                    Button(label(m)) { start(minutes: m) }
                        .buttonStyle(Pill())
                }
            }

            HStack {
                Stepper("\(customMinutes) min", value: $customMinutes, in: 5...480, step: 5)
                Button("Start") { start(minutes: customMinutes) }
                    .buttonStyle(Pill())
            }
            .padding(.top, 4)
        }
        .padding(24)
    }

    var countdown: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle().stroke(.white.opacity(0.08), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: [.indigo, .purple, .indigo], center: .center),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 40, weight: .light, design: .rounded).monospacedDigit())
                    Text("until sleep")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            .animation(.linear(duration: 0.5), value: progress)

            HStack(spacing: 12) {
                Button("+10 min") {
                    endDate = endDate?.addingTimeInterval(600)
                    total += 600
                }
                .buttonStyle(Pill())
                Button("Cancel") { stop() }
                    .buttonStyle(Pill())
            }
            .padding(.horizontal, 30)
        }
        .padding(24)
    }

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
        // Prevent App Nap from throttling the timer while windowed in the background
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep, reason: "ShutOff countdown"
        )
    }

    func stop() {
        endDate = nil
        if let a = activity {
            ProcessInfo.processInfo.endActivity(a)
            activity = nil
        }
    }

    func sleepMac() {
        // ponytail: two paths, no pmset. IOKit sleep is a direct kernel call (works when
        // the sandbox allows the IOPM port); if it fails, ask System Events via Apple Events,
        // which the sandbox permits through the apple-events entitlements + usage description.
        let port = IOPMFindPowerManagement(kIOMainPortDefault)
        if port != 0 {
            let r = IOPMSleepSystem(port)
            IOServiceClose(port)
            if r == kIOReturnSuccess { return }
        }
        NSAppleScript(source: "tell application \"System Events\" to sleep")?.executeAndReturnError(nil)
    }
}

struct Pill: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 6)
            .background(.white.opacity(configuration.isPressed ? 0.25 : 0.12),
                        in: RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
    }
}
