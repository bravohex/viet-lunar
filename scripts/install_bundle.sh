#!/usr/bin/env bash

# Stage first; retain the previous installation until promotion succeeds.
set -euo pipefail
[[ $# == 2 ]] || { echo "Usage: install_bundle.sh SOURCE DESTINATION" >&2; exit 2; }

bundle_source="$(cd "$1" && pwd -P)"
mkdir -p "$(dirname "$2")"
destination_parent="$(cd "$(dirname "$2")" && pwd -P)"
bundle_destination="$destination_parent/$(basename "$2")"

if [[ -d "$bundle_destination" ]]; then
  existing_path="$(cd "$bundle_destination" && pwd -P)"
  [[ "$bundle_source" != "$existing_path" ]] || {
    echo "Source and destination are the same app bundle; nothing changed." >&2; exit 1;
  }
fi
[[ ! -L "$bundle_destination" ]] || { echo "Refusing a symlink destination." >&2; exit 1; }
case "$bundle_source/" in "$bundle_destination/"*) echo "Source is inside destination." >&2; exit 1;; esac
case "$bundle_destination/" in "$bundle_source/"*) echo "Destination is inside source." >&2; exit 1;; esac

validate_bundle() {
  [[ -f "$1/Contents/Info.plist" ]] &&
    [[ "$(plutil -extract CFBundleIdentifier raw "$1/Contents/Info.plist")" == "com.bravohex.vietlunar" ]] &&
    [[ -x "$1/Contents/MacOS/VietLunar" ]]
}
validate_bundle "$bundle_source" || { echo "Invalid VietLunar source bundle." >&2; exit 1; }
if [[ -e "$bundle_destination" ]]; then
  validate_bundle "$bundle_destination" || { echo "Refusing to replace an unexpected bundle." >&2; exit 1; }
fi

staging_directory="$(mktemp -d "$destination_parent/.VietLunar-install.XXXXXX")"
cleanup() {
  result=$?
  if [[ -d "$staging_directory/previous.app" && ! -e "$bundle_destination" ]]; then
    if ! mv "$staging_directory/previous.app" "$bundle_destination"; then
      echo "Restore failed; previous app preserved at $staging_directory/previous.app" >&2
      exit 1
    fi
  fi
  rm -rf "$staging_directory"
  exit "$result"
}
trap cleanup EXIT

ditto "$bundle_source" "$staging_directory/new.app"
validate_bundle "$staging_directory/new.app" || { echo "Staged app failed validation." >&2; exit 1; }
if [[ -e "$bundle_destination" ]]; then
  mv "$bundle_destination" "$staging_directory/previous.app"
fi
mv "$staging_directory/new.app" "$bundle_destination"
