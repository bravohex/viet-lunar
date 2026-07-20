#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

xcrun swift "$PROJECT_ROOT/Tools/CalendarTableGenerator/main.swift" \
  --range 1800-01-01...2199-12-31 \
  --timezone +07:00 \
  --swift-output "$PROJECT_ROOT/Sources/Core/Generated/LunarYearTable.generated.swift" \
  --reference-output "$PROJECT_ROOT/ReferenceData/vietnam-lunar-1800-2199.reference.json"
