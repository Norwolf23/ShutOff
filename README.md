# ShutOff

A tiny native sleep timer for Mac and iPhone. Pick a duration, walk away.

- **Mac:** when the countdown hits zero the Mac goes to sleep. Music and video stop; nothing shuts down. Wake it with any key.
- **iPhone:** iOS won't let an app sleep the phone, so ShutOff stops whatever is playing instead (YouTube, Spotify, podcasts…). It plays silence in the background to keep the timer alive, then takes over the audio session at zero.

Made for falling asleep to a movie without it playing all night.

## Features

- Presets (15m – 2h) or any custom duration (5–480 min)
- Countdown ring with **+10 min** and **Cancel**
- Mac: full system sleep (IOKit, falling back to System Events), App Nap exemption so the timer can't stall
- One shared SwiftUI codebase (`Sources/`), platform differences confined to `Ender.swift`
- No dependencies, no accounts, no network

## Build

Requires Xcode and [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). macOS 13+ / iOS 17+.

```sh
xcodegen generate
xcodebuild -scheme ShutOff build                                                   # Mac
xcodebuild -scheme ShutOff-iOS -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Both targets are sandboxed / hardened-runtime for the App Store and share the bundle ID `studio.nickson.shutoff` (one listing). `swift makeicon.swift` renders the icons behind the two asset catalogs.

## License

MIT
