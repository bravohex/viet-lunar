#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="$PROJECT_ROOT/.build/PopoverMetricDerivedData"
DESTINATION="platform=macOS,arch=$(uname -m)"

xcodebuild \
  -quiet \
  -project "$PROJECT_ROOT/VietLunar.xcodeproj" \
  -scheme VietLunar \
  -configuration Release \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ENABLE_TESTABILITY=YES \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="-" \
  DEVELOPMENT_TEAM="" \
  ENABLE_HARDENED_RUNTIME=NO \
  test \
  -only-testing:VietLunarUITests/VietLunarUITests/testPopoverPerformanceSignposts

RESULT_PATH="$({
  find "$DERIVED_DATA_PATH/Logs/Test" -name '*.xcresult' -type d -print0
} | xargs -0 ls -td | head -1)"

xcrun xcresulttool get test-results metrics --path "$RESULT_PATH"
