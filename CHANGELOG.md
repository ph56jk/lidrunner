# Changelog

All notable changes to LidRunner are documented in this file.

The format is based on Keep a Changelog, and this project uses semantic
versioning once public releases begin.

## 0.2.4 - 2026-06-24

### Fixed

- Lid-close display sleep now waits until closed-lid mode is actually enabled,
  avoiding accidental full system sleep when macOS still has `SleepDisabled` off.

## 0.2.3 - 2026-06-24

### Changed

- Closing the lid while LidRunner is active now locks the session and then
  immediately requests display sleep with `pmset displaysleepnow`.

## 0.2.2 - 2026-06-24

### Added

- Lid-state monitoring through `AppleClamshellState`.
- Automatic screen locking when the MacBook lid closes while LidRunner is
  actively keeping the machine awake.

## 0.2.1 - 2026-06-24

### Added

- Optional privileged LaunchDaemon helper for closed-lid mode changes after
  one-time user approval.

### Changed

- Local staged app bundles now include the helper executable and LaunchDaemon
  plist, and are ad-hoc signed so ServiceManagement registration can work
  during development.

### Security

- XPC client validation for the privileged helper.

## 0.2.0 - 2026-06-24

### Added

- Launch-at-login toggle backed by `SMAppService.mainApp`.
- Charger-only mode that pauses awake assertions away from AC power.
- Preferences storage for awake mode, charger-only mode, and manual-launch window behavior.
- Power-source monitoring through IOKit notifications.
- Unit tests for preferences, power-source classification, and power policy decisions.

### Changed

- Awake assertions are now controlled through preference-driven power policy.
- Awake mode no longer blocks display sleep; it only prevents idle system sleep.
- Closed-lid mode uses a single checkbox so the current state is obvious.
- Charger-only mode now disables closed-lid mode whenever the Mac leaves AC power.
- The main window now has only three primary controls: enable LidRunner, charger-only mode, and launch at login.
- Local staged app bundles are ad-hoc signed so login item registration can work during development.

## 0.1.0 - Unreleased

### Added

- AppKit utility app with a status item and compact control window.
- IOKit awake assertions to prevent idle system and display sleep.
- Administrator-approved `pmset -a disablesleep` controls for closed-lid mode.
- SwiftPM build, test, app staging, and release packaging scripts.
- Unit tests for parsing current and custom `pmset` output.
