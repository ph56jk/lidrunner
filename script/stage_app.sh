#!/usr/bin/env bash
set -euo pipefail

APP_NAME="LidRunner"
BUNDLE_ID="com.lidrunner.app"
APP_VERSION="0.2.3"
APP_BUILD="9"
MIN_SYSTEM_VERSION="13.0"
CONFIGURATION="${CONFIGURATION:-debug}"
DAEMON_NAME="LidRunnerDaemon"
DAEMON_BUNDLE_ID="com.lidrunner.daemon"
DAEMON_PLIST_NAME="$DAEMON_BUNDLE_ID.plist"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_LAUNCH_DAEMONS="$APP_CONTENTS/Library/LaunchDaemons"
APP_BINARY="$APP_MACOS/$APP_NAME"
DAEMON_BINARY="$APP_MACOS/$DAEMON_NAME"
DAEMON_PLIST="$APP_LAUNCH_DAEMONS/$DAEMON_PLIST_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

cd "$ROOT_DIR"

swift build -c "$CONFIGURATION" --product "$APP_NAME" >&2
swift build -c "$CONFIGURATION" --product "$DAEMON_NAME" >&2
BUILD_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"
BUILD_DAEMON_BINARY="$BUILD_DIR/$DAEMON_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_LAUNCH_DAEMONS"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$BUILD_DAEMON_BINARY" "$DAEMON_BINARY"
chmod +x "$APP_BINARY"
chmod +x "$DAEMON_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright 2026 LidRunner contributors</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

cat >"$DAEMON_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$DAEMON_BUNDLE_ID</string>
  <key>BundleProgram</key>
  <string>Contents/MacOS/$DAEMON_NAME</string>
  <key>MachServices</key>
  <dict>
    <key>$DAEMON_BUNDLE_ID</key>
    <true/>
  </dict>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$DAEMON_BINARY" >/dev/null
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
fi

printf '%s\n' "$APP_BUNDLE"
