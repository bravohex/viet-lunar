# VietLunar review fixes implementation plan

> Execute inline, task by task, with regression checks and a separate commit per task.

**Goal:** Fix confirmed review defects and investigate/fix launch at login.
**Architecture:** Preserve the offline Core / Infrastructure / App boundaries, fixed UTC+7 calendar, macOS 13 floor, and Swift 6 concurrency checks. Keep macOS authorization under user control.
**Spec:** Findings from the 2026-10-26 review and the user's request to fix and commit each task.

## Tasks and acceptance

- [x] 1. Release entitlement verification: literal plist keys, reject debug/network entitlements; positive/negative fixture tests.
- [x] 2. Portable release checksums: use archive basename; verify downloaded-file layout.
- [x] 3. CI shell validation: parse every script; demonstrate invalid later file is rejected.
- [x] 4. Can–Chi refresh: include hour boundaries even with clock hidden; test default/clock configurations and 00:59/22:59 transitions.
- [x] 5. Icon plus clock: render icon with actual presentation title; test AppKit configuration and preview parity.
- [x] 6. Calendar range and refresh isolation: render supported days at both ends, preserve weekday positions, isolate grid failures, test AppState orchestration.
- [x] 7. Reference generator: find the containing lunation, enforce valid days, regenerate deterministically and compare every JSON row to runtime.
- [x] 8. Installer: reject source=destination, stage and validate before replacement, preserve previous install on failure; isolated fixture tests.
- [ ] 9. Launch at login: inspect installed-path/registration evidence, fix lifecycle/state/error handling and actionable installation guidance; mock regressions plus real registration verification where available.

## Review focus

- Hidden clock still exposes current Can–Chi hour in tooltip.
- First/last month padding must not shift weekdays or stop live updates.
- Failure unregistering must not falsely show login item disabled.
- Translocated/temporary bundles must not be presented as reliable login targets.
- Release tests must reject forbidden entitlements and installers must preserve existing data.

## Execution record

- Baseline: clean `main` at `8950c56`; previous review verified 85 Core and 15 Infrastructure tests. UI automation unavailable (macOS automation timeout).
- Ruling: work in the existing clean checkout on `feat/review-fixes`; no extra worktree or main-branch edits needed.
- Ruling: user authorized implementation/commits; proceed without another plan approval. New product features and independent astronomical-oracle acquisition are outside this bug-fix batch.

- Task 1 complete: literal entitlement checks; 4 fixture tests pass, real sandbox plist accepted. Prior workflow failure reproduced during review.

- Task 4: RED 4 failures, GREEN 86 Core + 15 Infrastructure tests. Default refresh now includes Can–Chi hour boundaries.

- Task 5: AppKit renderer regression RED (3 assertions) → GREEN; 86 Core + 15 Infrastructure + 2 App tests pass. Added hostless AppTests target for orchestration tests.

- Task 6: core boundary failure + 9 AppState assertions RED → GREEN; 87 Core + 15 Infrastructure + 4 App tests pass. Skip unsupported padding, add leading empty cells, compute navigation from supported bounds, rearm scheduler despite grid failure.

- Task 7: invalid reference row RED → GREEN; all 146,097 rows match runtime, 88 Core + 15 Infrastructure + 4 App tests pass. Regeneration repeated with identical checksums; runtime Swift table unchanged. Independent-oracle release gate remains open.

- Task 8: staged installer with source/alias protection and rollback; 9 script tests pass, including copy and promotion failures. Existing app is only stopped after successful installation.
