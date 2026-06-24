# Security Policy

LidRunner controls local macOS power settings and asks for administrator
approval when changing closed-lid behavior.

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
- Any future privileged helper or launch daemon
- Release packaging and code signing
- Automatic update mechanisms, if added later
