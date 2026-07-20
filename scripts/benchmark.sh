#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BENCHMARK_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/vietlunar-benchmark.XXXXXX")"
BENCHMARK_BINARY="$BENCHMARK_DIRECTORY/VietLunarBenchmark"
CORE_SOURCES=()

cleanup() {
  rm -rf "$BENCHMARK_DIRECTORY"
}
trap cleanup EXIT

while IFS= read -r source; do
  CORE_SOURCES+=("$source")
done < <(find "$PROJECT_ROOT/Sources/Core" -type f -name '*.swift' | sort)

xcrun swiftc \
  -O \
  -whole-module-optimization \
  -parse-as-library \
  -swift-version 6 \
  -strict-concurrency=complete \
  -warnings-as-errors \
  -module-name VietLunarBenchmark \
  -o "$BENCHMARK_BINARY" \
  "${CORE_SOURCES[@]}" \
  "$PROJECT_ROOT/Tools/Benchmark/main.swift"

"$BENCHMARK_BINARY"
