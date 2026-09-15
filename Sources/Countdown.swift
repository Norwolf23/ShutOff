import Foundation
import Combine

/// The one running countdown. Owned by the App (not a window), so closing the window,
/// a second window, or a Siri intent can't create or lose a timer.
final class Countdown: ObservableObject {
    static let shared = Countdown()

    @Published private(set) var endDate: Date?
    @Published private(set) var remaining: TimeInterval = 0   // whole seconds, for the menu bar
    private(set) var total: TimeInterval = 1
    private let ender = Ender()
    private var timer: Timer?
    private let store = UserDefaults.standard

    private init() {
        // Resume a countdown that was running when the app was last quit or killed.
        if let end = store.object(forKey: "end") as? Date, end > .now {
            total = max(store.double(forKey: "total"), 1)
            run(until: end)
        }
    }

    func start(minutes: Int) {
        total = TimeInterval(minutes * 60)
        run(until: .now + total)
    }

    func extend(_ seconds: TimeInterval = 600) {
        guard let end = endDate else { return }
        total += seconds
        run(until: end + seconds)
    }

    func stop() {
        clear()
        ender.cancel()
    }

    func progress(at date: Date) -> Double {
        guard let end = endDate else { return 0 }
        return max(0, end.timeIntervalSince(date)) / total
    }

    private func run(until end: Date) {
        endDate = end
        remaining = ceil(end.timeIntervalSinceNow)
        store.set(end, forKey: "end")
        store.set(total, forKey: "total")
        ender.begin(until: end)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.tick() }
        timer?.tolerance = 0.1
    }

    private func tick() {
        guard let end = endDate else { return }
        let left = end.timeIntervalSinceNow
        if left > 0 {
            if ceil(left) != remaining { remaining = ceil(left) }   // one publish per second, not per tick
            ender.tick(remaining: left)
            return
        }
        // ponytail: if we surface long after the deadline (the Mac slept on its own, iOS suspended us),
        // the moment has passed. Don't put a freshly woken Mac straight back to sleep.
        let late = -left > 30
        clear()
        late ? ender.cancel() : ender.fire()
    }

    private func clear() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        remaining = 0
        store.removeObject(forKey: "end")
    }
}

let presets = [15, 30, 45, 60, 90, 120]

func presetLabel(_ m: Int) -> String {
    m < 60 ? "\(m)m" : m % 60 == 0 ? "\(m / 60)h" : String(format: "%gh", Double(m) / 60)
}
