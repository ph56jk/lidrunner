# Contributing

Thanks for helping make LidRunner better.

## Development

Requirements:

- macOS 13 or newer
- Xcode command line tools
- Swift 5.9 or newer

Run the full local check:

```bash
./script/check.sh
```

Run the app:

```bash
./script/build_and_run.sh
```

Create a release archive:

```bash
./script/package_release.sh
```

## Pull requests

- Keep power-management behavior explicit and reversible.
- Add or update tests when parsing, command execution, or state handling changes.
- Avoid silently changing system settings without a visible user action.
- Include screenshots or short screen recordings for UI changes.

## Code style

Use the repository `.editorconfig`. Prefer small, plain AppKit components over
large abstractions until there is real repetition to remove.
