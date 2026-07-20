#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFERENCE_DATA_DIR="$PROJECT_ROOT/ReferenceData"

cd "$REFERENCE_DATA_DIR"

if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 -c SHA256SUMS
elif command -v sha256sum >/dev/null 2>&1; then
  sha256sum -c SHA256SUMS
else
  echo "No SHA-256 verification tool is available." >&2
  exit 1
fi
