#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

swift test
CONFIGURATION=release "$ROOT_DIR/script/stage_app.sh" >/dev/null
plutil -lint "$ROOT_DIR/dist/LidRunner.app/Contents/Info.plist"
