# Disturb Blocker

SwiftUI macOS menu bar app for timed focus modes. A mode can terminate selected apps and redirect Safari/Chrome tabs whose URL contains configured blocked text.

## Build

```sh
swift run DisturbBlockerCoreCheck
swift build --product DisturbBlocker
```

To create a menu bar `.app` bundle with `LSUIElement`:

```sh
chmod +x Scripts/package-app.sh
Scripts/package-app.sh
open .build/DisturbBlocker.app
```

## Permissions

- Accessibility permission is shown in the settings window and helps with macOS automation workflows.
- Safari/Chrome Automation permission is requested by macOS the first time the app reads or redirects browser tabs.
- The app is intended for personal local use and is not App Store sandboxed.

## Debugging

- Enable `Dry run` in Settings to log app/browser matches without terminating apps or redirecting tabs.
- Recent events in Settings show permission issues, schedule starts, app termination results, and browser redirect errors.
