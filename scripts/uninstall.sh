#!/usr/bin/env bash

set -euo pipefail

APP_NAME="VietLunar"
BUNDLE_IDENTIFIER="com.bravohex.vietlunar"
INSTALL_DIRECTORY="$HOME/Applications"
PURGE_DATA=false

usage() {
  cat <<'EOF'
Usage: ./scripts/uninstall.sh [--system] [--purge-data]

Removes VietLunar.app from ~/Applications by default. Use --system for an app
installed in /Applications. --purge-data additionally deletes the sandbox
container and preferences; it cannot be undone.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system)
      INSTALL_DIRECTORY="/Applications"
      shift
      ;;
    --purge-data)
      PURGE_DATA=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

APP_PATH="$INSTALL_DIRECTORY/${APP_NAME}.app"

echo "Before uninstalling, turn off ‘Mở VietLunar khi đăng nhập’ in Settings."
/usr/bin/pkill -x "$APP_NAME" 2>/dev/null || true

if [[ -e "$APP_PATH" ]]; then
  INFO_PLIST="$APP_PATH/Contents/Info.plist"
  if [[ ! -f "$INFO_PLIST" ]] || [[ "$(plutil -extract CFBundleIdentifier raw "$INFO_PLIST")" != "$BUNDLE_IDENTIFIER" ]]; then
    echo "Refusing to remove an unexpected app bundle: $APP_PATH" >&2
    exit 1
  fi
  rm -rf "$APP_PATH"
  echo "Removed: $APP_PATH"
else
  echo "No installed app found at: $APP_PATH"
fi

if "$PURGE_DATA"; then
  CONTAINER_PATH="$HOME/Library/Containers/$BUNDLE_IDENTIFIER"
  PREFERENCES_PATH="$HOME/Library/Preferences/$BUNDLE_IDENTIFIER.plist"
  rm -rf "$CONTAINER_PATH"
  rm -f "$PREFERENCES_PATH"
  echo "Removed local VietLunar data and preferences."
fi
