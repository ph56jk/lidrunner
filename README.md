# LidRunner

LidRunner is a small macOS utility for keeping local work alive when a MacBook
would normally go to sleep.

It is built for people running local development servers, automation jobs,
downloads, long-running scripts, or other tasks that should keep going while
the machine would otherwise idle.

## Features

- Starts IOKit awake assertions automatically when the app opens.
- Keeps idle system sleep disabled while allowing the display to sleep normally.
- Provides a menu bar status item and a compact three-control AppKit window.
- Can launch at login through macOS `SMAppService`.
- Can pause awake assertions automatically unless the Mac is on charger power.
- Uses a single `Enable LidRunner` switch to control both awake assertions and
  macOS closed-lid sleep prevention.
- Can install an optional bundled privileged helper so closed-lid mode changes
  do not require a password prompt every time.
- Reports closed-lid state from both current `SleepDisabled` output and older
  `disablesleep` custom output.
- Ships as a plain SwiftPM project with scripts for build, test, staging, and
  release packaging.

## Important Safety Note

Closed-lid behavior is controlled by macOS and hardware policy. Running a
MacBook closed can increase heat, especially under CPU or GPU load. Use a power
adapter, keep the machine ventilated, and stop closed-lid mode when you no
longer need it.

LidRunner does not silently change privileged settings. Enabling or disabling
closed-lid behavior uses macOS administrator approval. The optional privileged
helper still requires user approval before it is installed; it only avoids
repeating the password prompt for later closed-lid changes. If charger-only
mode is enabled, LidRunner stops awake assertions and disables closed-lid mode
as soon as the Mac leaves AC power.

## Requirements

- macOS 13 or newer
- Xcode command line tools
- Swift 5.9 or newer

## Build And Run

```bash
./script/build_and_run.sh
```

Verify that the app launches:

```bash
./script/build_and_run.sh --verify
```

Run the full local check:

```bash
./script/check.sh
```

Create a distributable zip:

```bash
./script/package_release.sh
```

The generated app bundle and release archives are written to `dist/`.

## How It Works

LidRunner uses several small layers:

- `PowerManager` creates an IOKit assertion and a `ProcessInfo` activity to
  prevent idle system sleep while allowing normal display sleep.
- `PowerSourceMonitor` watches IOKit power-source notifications.
- `PowerPolicy` decides whether awake assertions should run from preferences
  and the current power source.
- `LoginItemService` uses `SMAppService.mainApp` for launch-at-login.
- `PrivilegedPMSetService` can register a bundled LaunchDaemon through
  `SMAppService.daemon(plistName:)` and talk to it over XPC.
- `PMSetService` falls back to running `pmset -a disablesleep 1` or
  `pmset -a disablesleep 0` through `osascript` with administrator privileges
  when the helper is not enabled.

The second layer is intentionally user-triggered because it changes a
system-wide power setting.

More detail is available in [docs/power-management.md](docs/power-management.md).

## Development

The project is split into three targets:

- `LidRunnerCore`: preferences, policy, power-management services, and testable parsing logic.
- `LidRunner`: AppKit UI and app entrypoint.
- `LidRunnerDaemon`: optional privileged helper for passwordless `pmset` changes after user approval.

Run tests:

```bash
swift test
```

Stream app telemetry:

```bash
./script/build_and_run.sh --telemetry
```

## License

LidRunner is available under the MIT License. See [LICENSE](LICENSE).
