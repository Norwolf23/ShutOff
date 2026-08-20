# ShutOff 🌙

A tiny native macOS sleep timer. Pick a duration, walk away — when the countdown hits zero your Mac goes to sleep. Music and video stop; nothing shuts down. Wake it with any key.

Made for falling asleep to YouTube or a movie without it playing all night.

## Features

- Presets (15m – 2h) or any custom duration (5–480 min)
- Countdown ring with **+10 min** and **Cancel**
- Full system sleep via `pmset sleepnow` — not just display off, so audio stops too
- Timer tracks a target end time and holds an App Nap exemption, so it can't drift or stall in the background
- Single Swift file, no dependencies, no Xcode project

## Build & install

Requires macOS 13+ and Xcode command line tools (`xcode-select --install`).

```sh
./build.sh
cp -R build/ShutOff.app /Applications/
open /Applications/ShutOff.app
```

`build.sh` renders the icon (`makeicon.swift`), compiles `main.swift` with `swiftc`, assembles the bundle, and ad-hoc signs it. Takes a couple of seconds.

## License

MIT
