# ShutOff 🌙

A tiny native macOS sleep timer. Pick a duration, walk away — when the countdown hits zero your Mac goes to sleep. Music and video stop; nothing shuts down. Wake it with any key.

Made for falling asleep to YouTube or a movie without it playing all night.

## Features

- Presets (15m – 2h) or any custom duration (5–480 min)
- Countdown ring with **+10 min** and **Cancel**
- Full system sleep (IOKit, falling back to System Events) — not just display off, so audio stops too
- Timer tracks a target end time and holds an App Nap exemption, so it can't drift or stall in the background
- Single Swift file, no dependencies

## Build & install

Requires macOS 13+, Xcode, and [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
xcodegen generate && xcodebuild -scheme ShutOff -configuration Release build
```

The app is sandboxed and hardened-runtime for the Mac App Store; `makeicon.swift` renders the source icon behind `Assets.xcassets`.

## License

MIT
