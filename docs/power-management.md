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

## Charger-Only Mode

When charger-only mode is enabled, LidRunner treats only IOKit's `AC Power`
source as allowed for awake assertions. `Battery Power`, `UPS Power`, and
unknown power-source states pause awake assertions.

If closed-lid mode is enabled, LidRunner disables it when charger-only mode is
active and the Mac leaves AC power. It does not automatically re-enable
closed-lid mode when AC power returns, because that would create a surprise
administrator prompt.

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
