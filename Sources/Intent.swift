// Siri / Shortcuts: "Start ShutOff", "Cancel ShutOff".
import AppIntents

struct StartShutOff: AppIntent {
    static var title: LocalizedStringResource = "Start ShutOff"
    static var description = IntentDescription("Starts a sleep timer. When it ends the Mac sleeps, or on iPhone whatever is playing stops.")
    static var openAppWhenRun = true

    @Parameter(title: "Minutes", default: 45, inclusiveRange: (5, 480)) var minutes: Int

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        Countdown.shared.start(minutes: minutes)
        return .result(dialog: "ShutOff in \(minutes) minutes.")
    }
}

struct CancelShutOff: AppIntent {
    static var title: LocalizedStringResource = "Cancel ShutOff"
    static var description = IntentDescription("Cancels the running sleep timer.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        Countdown.shared.stop()
        return .result(dialog: "ShutOff cancelled.")
    }
}

struct ShutOffShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartShutOff(), phrases: ["Start \(.applicationName)"],
                    shortTitle: "Start timer", systemImageName: "moon")
        AppShortcut(intent: CancelShutOff(), phrases: ["Cancel \(.applicationName)"],
                    shortTitle: "Cancel timer", systemImageName: "moon.zzz")
    }
}
