// What happens when the countdown hits zero, per platform.
// macOS: the Mac sleeps.  iOS: whatever is playing stops (iOS won't let an app sleep the phone).
import Foundation

#if os(macOS)
import AppKit
import IOKit.pwr_mgt

final class Ender {
    static let promise = "Sleep this Mac after…"
    static let until = "until sleep"
    private var activity: NSObjectProtocol?

    func begin() {
        // Prevent App Nap from throttling the timer while windowed in the background
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep, reason: "ShutOff countdown")
    }

    func cancel() {
        if let a = activity { ProcessInfo.processInfo.endActivity(a); activity = nil }
    }

    func fire() {
        cancel()
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

#else
import AVFoundation

final class Ender {
    static let promise = "Stop whatever is playing after…"
    static let until = "until audio stops"
    private var player: AVAudioPlayer?
    private let session = AVAudioSession.sharedInstance()

    /// Play silence mixed with other apps so iOS keeps us alive in the background.
    func begin() {
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)
        player = try? AVAudioPlayer(data: Self.silence)
        player?.numberOfLoops = -1
        player?.volume = 0
        player?.play()
    }

    func cancel() {
        player?.stop(); player = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Re-activate as an exclusive playback session: iOS interrupts every other app's audio.
    /// Then deactivate WITHOUT notifyOthersOnDeactivation, so nothing resumes.
    func fire() {
        try? session.setCategory(.playback, options: [])
        try? session.setActive(true)
        player?.stop(); player = nil
        try? session.setActive(false)
    }

    // 1 s of 8 kHz mono 16-bit PCM zeros with a WAV header — no asset file needed.
    static let silence: Data = {
        let samples = 8000, bytes = samples * 2
        var d = Data()
        func u32(_ v: UInt32) { d.append(contentsOf: withUnsafeBytes(of: v.littleEndian, Array.init)) }
        func u16(_ v: UInt16) { d.append(contentsOf: withUnsafeBytes(of: v.littleEndian, Array.init)) }
        d.append(contentsOf: Array("RIFF".utf8)); u32(UInt32(36 + bytes)); d.append(contentsOf: Array("WAVE".utf8))
        d.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1); u32(8000); u32(16000); u16(2); u16(16)
        d.append(contentsOf: Array("data".utf8)); u32(UInt32(bytes)); d.append(Data(count: bytes))
        return d
    }()
}
#endif
