#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/VietLunar.xcodeproj"
DERIVED_DATA_PATH="$PROJECT_ROOT/.build/DerivedData"
DESTINATION="platform=macOS,arch=$(uname -m)"

xcodebuild -list -project "$PROJECT_PATH"

xcodebuild \
  -quiet \
  -project "$PROJECT_PATH" \
  -scheme VietLunar \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

xcodebuild \
  -quiet \
  -project "$PROJECT_PATH" \
  -scheme VietLunar \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  test
