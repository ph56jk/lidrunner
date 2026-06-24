# Releasing

This repository can produce an unsigned, ad-hoc-signed zip locally. Public
releases should be signed and notarized by a maintainer before distribution.

## Local Archive

```bash
./script/check.sh
./script/package_release.sh
```

The archive is written to:

```text
dist/releases/LidRunner-0.2.4-macos.zip
```

## Release Checklist

- Update `AppInfo.version`, `AppInfo.build`, `script/stage_app.sh`, and
  `script/package_release.sh`.
- Update `CHANGELOG.md`.
- Run `./script/check.sh`.
- Build `./script/package_release.sh`.
- Confirm the app bundle contains `Contents/MacOS/LidRunnerDaemon` and
  `Contents/Library/LaunchDaemons/com.lidrunner.daemon.plist`.
- Sign and notarize the app bundle for public distribution.
- Create a GitHub release with the zip and changelog notes.
