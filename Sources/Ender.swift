// What happens when the countdown hits zero, per platform.
// macOS: the Mac sleeps.  iOS: whatever is playing stops (iOS won't let an app sleep the phone).
import Foundation
import os

let log = Logger(subsystem: "studio.nickson.shutoff", category: "ender")

#if os(macOS)
import AppKit
import IOKit.pwr_mgt
import AudioToolbox

final class Ender {
    static let promise = "Sleep this Mac after…"
    static let until = "until sleep"
    static let fade: TimeInterval = 30   // seconds of volume fade before sleep
    private var activity: NSObjectProtocol?
    private var wake: NSObjectProtocol?

    init() {
        Volume.restore()   // quit mid-fade last time
        wake = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in Volume.restore() }
    }

    func begin(until _: Date) {
        cancel()
        // Prevent App Nap from throttling the timer while windowed in the background
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep, reason: "ShutOff countdown")
        askAutomationOnce()
    }

    /// Last 30 s: fade the system volume so the film doesn't cut off mid-line.
    func tick(remaining: TimeInterval) {
        guard remaining < Self.fade else { return }
        Volume.save()
        if let v = Volume.saved { Volume.level = v * Float(max(0, remaining) / Self.fade) }
    }

    func cancel() {
        if let a = activity { ProcessInfo.processInfo.endActivity(a); activity = nil }
        Volume.restore()
    }

    func fire() {
        if let a = activity { ProcessInfo.processInfo.endActivity(a); activity = nil }
        // Volume stays faded through sleep; didWake restores it. If sleep failed, restore in a minute.
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { Volume.restore() }
        // ponytail: two paths, no pmset. IOKit sleep is a direct kernel call (works when
        // the sandbox allows the IOPM port); if it fails, ask System Events via Apple Events,
        // which the sandbox permits through the apple-events entitlements + usage description.
        let port = IOPMFindPowerManagement(kIOMainPortDefault)
        if port != 0 {
            let r = IOPMSleepSystem(port)
            IOServiceClose(port)
            if r == kIOReturnSuccess { return }
            log.error("IOPMSleepSystem failed: \(r), falling back to System Events")
        }
        var err: NSDictionary?
        NSAppleScript(source: "tell application \"System Events\" to sleep")?.executeAndReturnError(&err)
        if let err { log.error("System Events sleep failed: \(err)") }
    }

    /// Trigger the "control System Events" prompt while someone is awake to click it,
    /// not at 2 am when the fallback would otherwise raise it for the first time.
    private func askAutomationOnce() {
        let key = "askedAutomation"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        NSAppleScript(source: "tell application \"System Events\" to get name")?.executeAndReturnError(nil)
    }
}

/// System output volume via CoreAudio (allowed in the sandbox). `saved` persists so a fade
/// interrupted by quit or sleep is undone on next launch or wake.
enum Volume {
    static var saved: Float? {
        get { UserDefaults.standard.object(forKey: "volume") as? Float }
        set { UserDefaults.standard.set(newValue, forKey: "volume") }
    }

    private static var device: AudioDeviceID {
        var id = AudioDeviceID(0), size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                              mScope: kAudioObjectPropertyScopeGlobal,
                                              mElement: kAudioObjectPropertyElementMain)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &id)
        return id
    }

    private static var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                                                         mScope: kAudioDevicePropertyScopeOutput,
                                                         mElement: kAudioObjectPropertyElementMain)

    static var level: Float {
        get {
            var v: Float32 = 1, size = UInt32(MemoryLayout<Float32>.size)
            AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &v)
            return v
        }
        set {
            var v = Float32(newValue)
            AudioObjectSetPropertyData(device, &addr, 0, nil, UInt32(MemoryLayout<Float32>.size), &v)
        }
    }

    static func save() { if saved == nil { saved = level } }
    static func restore() { if let v = saved { level = v; saved = nil } }
}

#else
import AVFoundation
import ActivityKit

final class Ender {
    static let promise = "Stop whatever is playing after…"
    static let until = "until audio stops"
    private var player: AVAudioPlayer?
    private let session = AVAudioSession.sharedInstance()
    private var activity: Activity<CountdownAttributes>?

    init() {
        // A call, Siri or another player interrupts our silent loop; pick it back up when they finish,
        // otherwise iOS suspends us and the timer dies with the music still playing.
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
                                               object: session, queue: .main) { [weak self] n in
            guard let self, self.player != nil,
                  let type = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  type == AVAudioSession.InterruptionType.ended.rawValue else { return }
            self.play()
        }
    }

    func begin(until end: Date) {
        play()
        liveActivity(until: end)
    }

    func tick(remaining _: TimeInterval) {}   // no cross-app volume API on iOS; no fade

    /// Play silence mixed with other apps so iOS keeps us alive in the background.
    private func play() {
        do {
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            if player == nil {
                player = try AVAudioPlayer(data: Self.silence)
                player?.numberOfLoops = -1
                player?.volume = 0
            }
            player?.play()
        } catch { log.error("keep-alive audio failed: \(error)") }
    }

    func cancel() {
        player?.stop(); player = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        endActivity()
    }

    /// Re-activate as an exclusive playback session: iOS interrupts every other app's audio.
    /// Then deactivate WITHOUT notifyOthersOnDeactivation, so nothing resumes.
    func fire() {
        do {
            try session.setCategory(.playback, options: [])
            try session.setActive(true)
            player?.stop(); player = nil
            try session.setActive(false)
        } catch { log.error("audio takeover failed: \(error)") }
        endActivity()
    }

    // Lock-screen / Dynamic Island countdown.
    private func liveActivity(until end: Date) {
        let content = ActivityContent(state: CountdownAttributes.ContentState(end: end), staleDate: end)
        if let a = activity { Task { await a.update(content) }; return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do { activity = try Activity.request(attributes: CountdownAttributes(), content: content) }
        catch { log.error("live activity failed: \(error)") }
    }

    private func endActivity() {
        let a = activity; activity = nil
        Task { await a?.end(nil, dismissalPolicy: .immediate) }
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
