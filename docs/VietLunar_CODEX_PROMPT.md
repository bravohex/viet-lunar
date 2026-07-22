# Ready-to-paste Codex prompt — VietLunar MVP

You are implementing a native macOS menu-bar application named **VietLunar**.

Read these files in full before editing:

1. `docs/VietLunar_SPEC.md`
2. `docs/VietLunar_CODEX_PLAN.md`
3. `ReferenceData/README.md`, if present
4. all existing ADRs

## Objective for this run

Implement the next incomplete MVP milestone only. Begin with M0 if the repository is empty. Do not implement future events unless the operator explicitly changes scope.

## Non-negotiable constraints

- macOS 13.0+.
- Native Swift; SwiftUI `MenuBarExtra` window style, with minimal AppKit only where needed.
- Hidden Dock icon by default; explicit Quit action.
- Fully offline; no backend, telemetry, ads, WebView, Electron, or network dependency.
- Apple-framework runtime dependencies only.
- Vietnamese lunar conversion uses canonical UTC+7 and a generated, immutable, verified table for 1800-01-01...2199-12-31.
- Do not substitute Foundation’s Chinese calendar.
- Outside the verified range, return typed errors; never approximate.
- Can–Chi formulas and day-boundary policy must follow the spec.
- Only when the operator explicitly accepts this scope, giờ hoàng đạo may be shown as an offline cultural-reference lookup from the selected civil date's day branch; never present personal, activity-specific, or outcome-based advice.
- No one-second polling. Default mode has no repeating timer.
- `SMAppService.mainApp` is the login-item mechanism.
- User preferences go through a typed store; future events use a repository abstraction and later SQLite.
- Preserve Vietnamese diacritics and accessibility labels.
- Any reference data or copied code needs provenance, checksum, attribution, and compatible licensing.

## Work protocol

1. Inspect the repository and identify the next incomplete task ID.
2. Before editing, output:
   - selected task ID;
   - concise file plan;
   - tests that will prove completion;
   - any actual blocker not resolved by the spec.
3. Implement the smallest coherent task, including tests.
4. Run the relevant `xcodebuild`/script commands.
5. Do not weaken tests to make them pass.
6. At the end, report:
   - changed files;
   - behavior implemented;
   - commands and results;
   - accuracy/data provenance impact;
   - remaining tasks and risks.

## Accuracy warning

Calendar correctness is release-critical. The production table and an independent reference must be compared exhaustively. Rare leap-month behavior, especially 2033, is an explicit release gate. Do not infer a missing golden value from the production engine itself.

## First-run instruction for an empty repository

Complete M0.1–M0.3 only:

- create/normalize the Xcode project and schemes;
- add a minimal `MenuBarExtra` app showing `ÂL`;
- hide the Dock icon;
- provide placeholder popover with Settings and Quit;
- add test/build scripts and repository scaffolding;
- do not add lunar conversion code yet.
