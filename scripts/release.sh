#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_SOURCE="$PROJECT_ROOT/Tools/ProjectGenerator/generate_project.rb"
PROJECT_FILE="$PROJECT_ROOT/VietLunar.xcodeproj/project.pbxproj"
REMOTE_NAME="origin"
PUSH_RELEASE=false
VERSION=""
BUILD_NUMBER=""

usage() {
  cat <<'EOF'
Usage: ./scripts/release.sh VERSION [--build NUMBER] [--push]

Prepares an annotated VietLunar release tag:
  1. Updates MARKETING_VERSION and CURRENT_PROJECT_VERSION.
  2. Regenerates the Xcode project and runs local non-UI tests.
  3. Commits the version change and creates tag vVERSION named "VietLunar vVERSION".

Use --push to push both the current branch and release tag to origin. The
working tree must be clean before the script starts.
EOF
}

fail() {
  echo "Release preparation failed: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build)
      [[ $# -ge 2 ]] || fail "--build requires a positive integer."
      BUILD_NUMBER="$2"
      shift 2
      ;;
    --push)
      PUSH_RELEASE=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      fail "Unknown option: $1"
      ;;
    *)
      [[ -z "$VERSION" ]] || fail "Only one version can be supplied."
      VERSION="$1"
      shift
      ;;
  esac
done

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  usage >&2
  fail "VERSION must use semantic format X.Y.Z."
}

if [[ -n "$BUILD_NUMBER" ]] && [[ ! "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
  fail "--build must be a positive integer."
fi

cd "$PROJECT_ROOT"
git rev-parse --is-inside-work-tree >/dev/null
git diff --quiet || fail "Commit or stash unstaged changes first."
git diff --cached --quiet || fail "Commit or unstage staged changes first."

BRANCH_NAME="$(git branch --show-current)"
[[ -n "$BRANCH_NAME" ]] || fail "Checkout a branch before preparing a release."
git remote get-url "$REMOTE_NAME" >/dev/null 2>&1 || fail "Remote '$REMOTE_NAME' is not configured."

TAG_NAME="v$VERSION"
if git rev-parse -q --verify "refs/tags/$TAG_NAME" >/dev/null; then
  fail "Tag $TAG_NAME already exists locally."
fi
if git ls-remote --exit-code --tags "$REMOTE_NAME" "refs/tags/$TAG_NAME" >/dev/null 2>&1; then
  fail "Tag $TAG_NAME already exists on $REMOTE_NAME."
fi

if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER="$(ruby -e '
    source = File.read(ARGV.fetch(0))
    match = source.match(/settings\["CURRENT_PROJECT_VERSION"\] = "([0-9]+)"/)
    abort "CURRENT_PROJECT_VERSION was not found" unless match
    puts Integer(match[1]) + 1
  ' "$VERSION_SOURCE")"
fi

ruby - "$VERSION_SOURCE" "$VERSION" "$BUILD_NUMBER" <<'RUBY'
path, version, build_number = ARGV
source = File.read(path)

marketing_matches = source.scan(/settings\["MARKETING_VERSION"\] = "[^"]+"/).length
build_matches = source.scan(/settings\["CURRENT_PROJECT_VERSION"\] = "[^"]+"/).length
abort "MARKETING_VERSION was not found exactly once" unless marketing_matches == 1
abort "CURRENT_PROJECT_VERSION was not found exactly once" unless build_matches == 1

source.gsub!(
  /settings\["MARKETING_VERSION"\] = "[^"]+"/,
  "settings[\"MARKETING_VERSION\"] = \"#{version}\""
)
source.gsub!(
  /settings\["CURRENT_PROJECT_VERSION"\] = "[^"]+"/,
  "settings[\"CURRENT_PROJECT_VERSION\"] = \"#{build_number}\""
)

File.write(path, source)
RUBY

ruby Tools/ProjectGenerator/generate_project.rb
./scripts/verify_reference_data.sh
./scripts/test.sh --skip-ui
git diff --check

git add "$VERSION_SOURCE" "$PROJECT_FILE" VietLunar.xcodeproj/xcshareddata/xcschemes/VietLunar.xcscheme
git diff --cached --quiet && fail "Version update produced no changes."

RELEASE_NAME="VietLunar $TAG_NAME"
git commit -m "Release: $TAG_NAME"
git tag -a "$TAG_NAME" -m "$RELEASE_NAME"

echo "Created commit and annotated tag $TAG_NAME ($RELEASE_NAME)."
if "$PUSH_RELEASE"; then
  git push "$REMOTE_NAME" "$BRANCH_NAME"
  git push "$REMOTE_NAME" "$TAG_NAME"
  echo "Pushed $BRANCH_NAME and $TAG_NAME. GitHub Actions release has started."
else
  echo "Review locally, then push with:"
  echo "  git push $REMOTE_NAME $BRANCH_NAME"
  echo "  git push $REMOTE_NAME $TAG_NAME"
fi
