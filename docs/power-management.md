# Power Management Notes

LidRunner has to work with macOS power-management policy rather than around it.
This document explains the boundaries.

## Awake Assertions

When awake mode starts, LidRunner creates:

- `kIOPMAssertionTypePreventUserIdleSystemSleep`
- A `ProcessInfo` activity with idle sleep disabled

These assertions behave like a focused app-level version of `caffeinate`. They
are released when the user stops awake mode or the app exits.

LidRunner intentionally does not create a display-sleep assertion. The display
can turn off according to macOS display settings while system sleep remains
blocked.

You can inspect active assertions with:

```bash
pmset -g assertions
```

## Closed-Lid Mode

Closing a MacBook lid is a stronger system policy than idle sleep. On systems
that accept it, LidRunner toggles:

```bash
pmset -a disablesleep 1
```

and restores it with:

```bash
pmset -a disablesleep 0
```

This requires administrator approval and affects the whole machine, not only
LidRunner.

On newer macOS versions, `pmset -g` may report the state as `SleepDisabled`
instead of showing `disablesleep` in `pmset -g custom`. LidRunner checks both.

## Screen Locking

When LidRunner prevents closed-lid sleep, macOS no longer reaches the normal
sleep-lock path. LidRunner therefore watches `AppleClamshellState` and locks the
current user session when the lid changes to closed while LidRunner is actively
running.

The lock uses:

```bash
/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession -suspend
```

This keeps background work alive while still requiring the user to unlock the
session after opening the machine again.

## Privileged Helper

macOS does not allow LidRunner to change closed-lid policy without privileged
approval. To make daily use less noisy, the app bundle includes an optional
LaunchDaemon helper. The user installs it from the menu bar item, approves the
background item in macOS, and LidRunner then sends closed-lid changes to the
helper over XPC.

The helper is registered with `SMAppService.daemon(plistName:)` and is bundled
inside the app:

- Executable: `Contents/MacOS/LidRunnerDaemon`
- LaunchDaemon plist: `Contents/Library/LaunchDaemons/com.lidrunner.daemon.plist`

If the helper is not enabled, LidRunner falls back to the normal administrator
prompt path using `osascript`.

## Charger-Only Mode

When charger-only mode is enabled, LidRunner treats only IOKit's `AC Power`
source as allowed for awake assertions. `Battery Power`, `UPS Power`, and
unknown power-source states pause awake assertions.

If closed-lid mode is enabled, LidRunner disables it when charger-only mode is
active and the Mac leaves AC power. When AC power returns and `Enable LidRunner`
is still on, LidRunner attempts to resume closed-lid mode. Installing the
privileged helper avoids repeated password prompts for that automatic resume.

The UI intentionally exposes only three primary controls:

- `Enable LidRunner`
- `Only on Charger`
- `Launch at Login`

## Launch At Login

LidRunner uses `SMAppService.mainApp` on macOS 13 and newer. The app bundle must
be code signed for registration to work; local development builds are ad-hoc
signed by `script/stage_app.sh`.

## Limitations

- Some hardware or macOS builds may reject the hidden `disablesleep` setting.
- Thermal behavior is the user's responsibility when running closed.
- LidRunner is not a code-signed or notarized release until a maintainer signs
  and notarizes published artifacts.
