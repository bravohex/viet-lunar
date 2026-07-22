#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="VietLunar"
BUNDLE_IDENTIFIER="com.bravohex.vietlunar"
DERIVED_DATA_PATH="$PROJECT_ROOT/.build/DevDerivedData"
APP_SOURCE=""
INSTALL_DIRECTORY="$HOME/Applications"
LAUNCH_AFTER_INSTALL=true

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [--app PATH] [--system] [--no-launch]

Builds and installs the Debug app into ~/Applications by default. Use --app to
install an existing signed or notarized VietLunar.app bundle instead. --system
installs into /Applications and may require administrator permission.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      [[ $# -ge 2 ]] || { echo "--app requires a path." >&2; exit 2; }
      APP_SOURCE="$2"
      shift 2
      ;;
    --system)
      INSTALL_DIRECTORY="/Applications"
      shift
      ;;
    --no-launch)
      LAUNCH_AFTER_INSTALL=false
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

if [[ -z "$APP_SOURCE" ]]; then
  xcodebuild \
    -quiet \
    -project "$PROJECT_ROOT/VietLunar.xcodeproj" \
    -scheme VietLunar \
    -configuration Debug \
    -destination "platform=macOS,arch=$(uname -m)" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build
  APP_SOURCE="$DERIVED_DATA_PATH/Build/Products/Debug/${APP_NAME}.app"
fi

if [[ ! -d "$APP_SOURCE" ]]; then
  echo "App bundle was not found: $APP_SOURCE" >&2
  exit 1
fi

INFO_PLIST="$APP_SOURCE/Contents/Info.plist"
if [[ ! -f "$INFO_PLIST" ]] || [[ "$(plutil -extract CFBundleIdentifier raw "$INFO_PLIST")" != "$BUNDLE_IDENTIFIER" ]]; then
  echo "Expected a ${BUNDLE_IDENTIFIER} app bundle: $APP_SOURCE" >&2
  exit 1
fi

APP_DESTINATION="$INSTALL_DIRECTORY/${APP_NAME}.app"
mkdir -p "$INSTALL_DIRECTORY"
/usr/bin/pkill -x "$APP_NAME" 2>/dev/null || true
rm -rf "$APP_DESTINATION"
ditto "$APP_SOURCE" "$APP_DESTINATION"

echo "Installed: $APP_DESTINATION"
if "$LAUNCH_AFTER_INSTALL"; then
  open "$APP_DESTINATION"
fi
