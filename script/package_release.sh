#!/usr/bin/env bash
set -euo pipefail

APP_NAME="LidRunner"
APP_VERSION="0.2.3"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_DIR="$ROOT_DIR/dist/releases"
ZIP_PATH="$ARCHIVE_DIR/$APP_NAME-$APP_VERSION-macos.zip"

mkdir -p "$ARCHIVE_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
APP_BUNDLE="$(CONFIGURATION=release "$ROOT_DIR/script/stage_app.sh")"

rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
printf '%s\n' "$ZIP_PATH"
