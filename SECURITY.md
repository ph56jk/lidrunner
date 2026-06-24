# Security Policy

LidRunner controls local macOS power settings and asks for administrator
approval when changing closed-lid behavior. The optional privileged helper also
requires user approval before it can run.

## Reporting a vulnerability

Please open a private security advisory on GitHub when the repository is
published, or email the maintainer listed in the project profile.

Useful reports include:

- A clear description of the issue
- Steps to reproduce
- macOS version and hardware model
- Whether administrator approval was involved

## Scope

Security-sensitive areas include:

- Commands run through `osascript` or `pmset`
- The bundled privileged helper and LaunchDaemon plist
- XPC communication between the app and helper
- Release packaging and code signing
- Automatic update mechanisms, if added later

The helper rejects XPC clients whose code-signing identifier does not match the
main app bundle identifier. Public releases should still be signed and
notarized by a maintainer so this identity check is backed by a real signing
chain instead of local ad-hoc signatures.
