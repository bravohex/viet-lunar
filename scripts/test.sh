#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/VietLunar.xcodeproj"
DERIVED_DATA_PATH="$PROJECT_ROOT/.build/DerivedData"
DESTINATION="platform=macOS,arch=$(uname -m)"

"$PROJECT_ROOT/scripts/verify_localizations.sh"

xcodebuild -list -project "$PROJECT_PATH"

xcodebuild \
  -quiet \
  -project "$PROJECT_PATH" \
  -scheme VietLunar \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

test -f "$DERIVED_DATA_PATH/Build/Products/Debug/VietLunar.app/Contents/Resources/vi.lproj/Localizable.strings"
test -f "$DERIVED_DATA_PATH/Build/Products/Debug/VietLunar.app/Contents/Resources/Assets.car"
test "$(plutil -extract CFBundleIconName raw "$DERIVED_DATA_PATH/Build/Products/Debug/VietLunar.app/Contents/Info.plist")" = "AppIcon"
xcrun assetutil --info \
  "$DERIVED_DATA_PATH/Build/Products/Debug/VietLunar.app/Contents/Resources/Assets.car" | \
  ruby -rjson -e '
    expected = %w[
      AppIcon VLInfo VLMenuBarLunar VLNext VLPrevious VLQuit VLSettings VLToday
    ]
    names = JSON.parse(STDIN.read).filter_map { |entry| entry["Name"] }
    missing = expected - names
    abort "Missing compiled icon assets: #{missing.join(", ")}" unless missing.empty?
  '
test -f "$DERIVED_DATA_PATH/Build/Products/Debug/VietLunar.app/Contents/Frameworks/VietLunarCore.framework/Versions/A/Resources/vi.lproj/Localizable.strings"
test ! -e "$DERIVED_DATA_PATH/Build/Products/Debug/VietLunar.app/Contents/Frameworks/VietLunarInfrastructure.framework"

xcodebuild \
  -quiet \
  -project "$PROJECT_PATH" \
  -scheme VietLunar \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  test
