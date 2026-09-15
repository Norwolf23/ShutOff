# ShutOff — App Store listing (first draft)

Paste-ready for App Store Connect. Mac and iPhone ship under one bundle ID (`studio.nickson.shutoff`), so it is ONE listing with one description; the platform sections inside the description tell each reader what their device does. Same layout as the Stayawake listing.

> Naming: "ShutOff" reads right on the Mac (it puts the Mac to sleep). On iPhone it only stops audio, so the name may need to change or get a subtitle that says so. Parked for now — see "Open questions" at the bottom.

## Name
ShutOff

## Subtitle (30 chars max)
Sleep timer for Mac and iPhone

Alternatives: `Fall asleep. It shuts off.` (26) · `Timer that puts it to sleep` (27)

## Promotional text (170 chars max)
Pick a time, fall asleep. On the Mac the whole machine goes to sleep. On iPhone whatever is playing stops. A moon wanes as the time runs out. No accounts, no ads.

## Description
ShutOff is a sleep timer. Pick how long, put the device down, fall asleep. When the moon goes dark, it shuts off.

Tap the moon or a preset (15 min to 2 hours, or set your own in 5-minute steps). A full moon appears and slowly wanes as the time runs out. Need a bit more? +10 min. Changed your mind? Cancel.

ON THE MAC
• Puts the whole Mac to sleep when the timer ends, exactly like choosing Sleep from the Apple menu. Video stops, audio stops, the screen goes dark, downloads and open documents are untouched.
• Nothing is shut down, closed, or lost. Press any key in the morning and everything is where you left it.
• The timer keeps running while ShutOff is in the background or behind a full-screen video. It holds a small system exemption so macOS never pauses the countdown, and releases it the moment the timer ends or is cancelled.
• A menu-bar moon shows the time left and lets you start, extend or cancel without opening the window. Close the window and the timer keeps running.
• The volume fades down over the last half-minute, so a film doesn't cut off mid-line. Your volume comes back when the Mac wakes.
• Made for falling asleep to a film or a YouTube autoplay chain without it running all night.
• Resizable window, fullscreen-friendly. Looks as good on a 27" display as in a small corner.

ON THE iPHONE
• iOS does not let any app lock or sleep the phone, so ShutOff does the thing that matters: it stops the audio. Podcasts, music, YouTube, audiobooks, white noise — whatever is playing stops when the timer ends and stays stopped.
• Works with every app. ShutOff does not need to be the player; it just tells iOS to hand the audio back.
• A Live Activity counts down on the lock screen and in the Dynamic Island, so you can glance at the time left without unlocking.
• Keeps counting with the screen locked and ShutOff in the background. It stays awake by playing silence, then takes the audio session at zero. Nothing is played through your speaker. A phone call or Siri won't break the timer.
• Start it, lock the phone, sleep.

ANYWHERE
• Ask Siri or run a Shortcut: "Start ShutOff", "Cancel ShutOff".
• Quit and reopen and a running timer picks up where it left off.

THE MOON
The countdown is a moon. Full when you start, half when you're halfway, a thin crescent near the end, dark at zero. Soft watercolour surface, thin lines, a night sky. Nothing bright to keep you awake.

No accounts. No ads. No tracking. No network access. It does one thing and does it well.

## Keywords (100 chars max, comma separated)
sleep timer,shutoff,auto sleep,stop music,stop audio,fall asleep,moon,night,bedtime,shutdown timer

(98 characters. Do not repeat words from the name or subtitle; ASC ignores them.)

## What's New (version 1.0)
First release.

## URLs
Support URL: https://nickson.studio/apps/privacy.html
Marketing URL: (leave blank)
Privacy Policy URL: https://nickson.studio/apps/privacy.html

## Category
Primary: Utilities
Secondary: (none)

## Price
Free

## Age rating
All questionnaire answers: None / No → 4+

## App Privacy
Data Not Collected. (Needs the Admin role in ASC to submit.)

## Export compliance
"Does your app use encryption?" → No. `ITSAppUsesNonExemptEncryption` is false in both builds.

## Review notes (paste into "Notes" on each platform version)

### macOS
ShutOff is a sleep timer. Pick a duration, and when it ends the Mac is put to sleep — the same as Apple menu > Sleep. It never shuts down, restarts or logs out.

How sleep is triggered inside the App Sandbox: the app first asks IOKit power management (IOPMSleepSystem). If the sandbox refuses that port, it falls back to an Apple Event: `tell application "System Events" to sleep`. That is why the build carries `com.apple.security.temporary-exception.apple-events` for `com.apple.systemevents` and `NSAppleEventsUsageDescription`. No other Apple Events are sent and no other apps are scripted. On first use macOS shows the standard "ShutOff wants to control System Events" prompt; the usage string explains why.

While a timer runs the app holds `ProcessInfo.beginActivity(.userInitiatedAllowingIdleSystemSleep)` so App Nap cannot pause the countdown while the window is in the background. The activity is ended when the timer fires or is cancelled. The app never prevents sleep; it only prevents its own timer from being throttled.

To test: set a 5-minute timer (or use the custom stepper for 5 min), leave a video playing in another app, wait. The Mac sleeps at zero. Wake with any key.

No login, no account, no network, no third-party SDKs. Sandboxed, hardened runtime.

### iOS
ShutOff is a sleep timer that stops audio playback from other apps when the timer ends. iOS provides no API to lock or sleep the device, so stopping audio is the whole feature, and the listing says so.

Background audio mode is declared (`UIBackgroundModes: audio`). While a timer is running the app plays a silent, in-memory audio loop with the `.mixWithOthers` option so the user's music/podcast continues and iOS keeps the app alive with the screen locked. When the timer reaches zero the app re-activates its AVAudioSession as a non-mixable `.playback` session, which causes iOS to interrupt every other app's audio, then deactivates without `notifyOthersOnDeactivation` so the other apps stay paused. The silent track is stopped and the session released; nothing audible is ever produced. Cancelling a timer releases the session and lets other audio continue. If a phone call or Siri interrupts the silent loop, the app restarts it when the interruption ends so the timer survives.

The app shows a Live Activity (lock screen + Dynamic Island) counting down to zero, via an embedded WidgetKit extension (`studio.nickson.shutoff.widgets`). The activity displays only the remaining time; it collects nothing.

To test: play music in Apple Music or Spotify, open ShutOff, set a 5-minute timer, lock the phone. At zero the music stops. The remaining time is visible on the lock screen while it counts down.

No login, no account, no network, no notifications (Live Activities are local, not push), no third-party SDKs.

## Screenshots to capture
Mac (1280×800 and 2560×1600, from the app window on a plain desktop):
1. Idle screen — moon and presets
2. Countdown just started — full moon, "44:59 until sleep"
3. Countdown near the end — thin crescent
4. Fullscreen on a large display (shows scaling)

iPhone (6.9" and 6.5" from the simulator, portrait):
1. Idle screen — moon and presets ("Stop whatever is playing after…")
2. Countdown just started — full moon
3. Countdown halfway — half moon
4. Countdown near the end — crescent

Optional app preview video (Mac): 15 s, 5-min timer sped up, moon waning, Mac sleeps.

## Open questions before submission
- **iPhone name.** "ShutOff" promises more than iOS allows. Options: keep the name and let the subtitle carry it ("Sleep timer for Mac and iPhone"); or rename the iOS listing later. Renaming would need a second bundle ID and a separate listing — one listing means one name. Decide before the first upload; the name is changeable later but the bundle ID is not.
- **On-device audio test.** The iOS audio takeover has only been built, not verified on a real phone with third-party audio. Test before uploading.
- **ASC record.** App record for `studio.nickson.shutoff` does not exist yet. Create it under Nicholas's team (6272CRNH9G), then upload Mac and iOS builds (`ExportOptions` destination `upload`, run by Gustav with `!`).
- **App Privacy** and the **EU trader status / DPLA** warnings need the Account Holder or Admin, same as Stayawake.
