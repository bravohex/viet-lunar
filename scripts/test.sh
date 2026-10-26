#!/usr/bin/env bash

set -euo pipefail

skip_performance_test=false
skip_ui_tests=false

usage() {
  cat <<'EOF'
Usage: ./scripts/test.sh [--skip-performance] [--skip-ui]

Options:
  --skip-performance  Skip the non-deterministic XCUITest signpost measurement.
                      Use this on shared CI runners; run ./scripts/measure_popover.sh
                      locally for the Release performance measurement.
  --skip-ui           Skip the entire UI-test target. Used by scripts/release.sh
                      for its local pre-tag verification.
EOF
}

for argument in "$@"; do
  case "$argument" in
    --skip-performance)
      skip_performance_test=true
      ;;
    --skip-ui)
      skip_ui_tests=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/VietLunar.xcodeproj"
DERIVED_DATA_PATH="$PROJECT_ROOT/.build/DerivedData"
DESTINATION="platform=macOS,arch=$(uname -m)"
test_arguments=()

if [[ "$skip_ui_tests" == true ]]; then
  test_arguments+=("-skip-testing:VietLunarUITests")
elif [[ "$skip_performance_test" == true ]]; then
  test_arguments+=(
    "-skip-testing:VietLunarUITests/VietLunarUITests/testPopoverPerformanceSignposts"
  )
fi

test -f "$PROJECT_ROOT/LICENSE"
grep -Eq '^MIT License$' "$PROJECT_ROOT/LICENSE"
grep -Eq '^Copyright \(c\) 2026 bravohex$' "$PROJECT_ROOT/LICENSE"

"$PROJECT_ROOT/scripts/verify_localizations.sh"
python3 -m unittest discover -s "$PROJECT_ROOT/Tests/ScriptTests" -p 'test_*.py'

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
test "$(plutil -extract CFBundleIdentifier raw "$DERIVED_DATA_PATH/Build/Products/Debug/VietLunar.app/Contents/Info.plist")" = "com.bravohex.vietlunar"
test "$(plutil -extract CFBundleIconName raw "$DERIVED_DATA_PATH/Build/Products/Debug/VietLunar.app/Contents/Info.plist")" = "AppIcon"
test "$(plutil -extract NSHumanReadableCopyright raw "$DERIVED_DATA_PATH/Build/Products/Debug/VietLunar.app/Contents/Info.plist")" = "Copyright © 2026 bravohex"
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
  "${test_arguments[@]}" \
  test
