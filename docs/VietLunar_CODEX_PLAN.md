# VietLunar — Codex Implementation Plan

**Companion document:** `VietLunar_SPEC.md`  
**Rule:** Complete tasks in order. Do not begin future event implementation during the MVP unless explicitly requested.

---

## 1. Working method required from Codex

For each task:

1. Read the relevant spec sections.
2. Inspect the existing repository before editing.
3. State files to add/change and any assumption that is not already resolved.
4. Make the smallest coherent change.
5. Add or update tests in the same change.
6. Run the exact relevant test/build commands.
7. Report changed files, tests, and unresolved risk.
8. Do not replace a failing accuracy test by weakening expectations.
9. Do not introduce third-party runtime packages.
10. Stop at the milestone boundary requested by the operator.

Recommended commit style:

```text
M0: bootstrap native macOS menu-bar project
M1: add validated date and JDN core types
M2: add generated Vietnamese lunar table and engine
M3: implement Can-Chi and snapshot factory
M4: implement month-grid domain model
M5: implement MenuBarExtra UI
M6: implement lifecycle refresh scheduler
M7: implement settings and launch at login
M8: complete exhaustive tests, profiling, release docs
```

---

## 2. Repository bootstrap — M0

### Task M0.1 — Establish project and targets

Create or normalize:

- macOS application target `VietLunar`;
- core target/module `VietLunarCore` if practical;
- infrastructure target/module `VietLunarInfrastructure` if practical;
- unit test targets;
- UI test target;
- deployment target macOS 13.0;
- Swift 6 language mode where supported;
- strict concurrency diagnostics.

If the repository is empty and Codex cannot safely author an Xcode project from scratch, create all source and test directories plus a deterministic project-generation file, but record that Xcode project generation is a development-only operation. No project generator may become a runtime dependency.

#### Definition of done

- `xcodebuild -list` shows the expected scheme.
- A minimal app compiles.
- Tests can be discovered.
- No external runtime package appears in `Package.resolved`.

### Task M0.2 — Configure menu-bar application behavior

Add:

- `MenuBarExtra` shell;
- placeholder label `ÂL`;
- window-style menu extra;
- placeholder popover with version and Quit;
- hidden Dock icon using one chosen mechanism;
- settings scene placeholder.

Do not implement calendar calculations yet.

#### Tests/manual checks

- app appears in menu bar;
- no Dock icon under default configuration;
- popover opens;
- Quit works;
- Settings can receive focus.

### Task M0.3 — Add repository standards

Add:

- `.gitignore` for Xcode/macOS;
- `README.md` scaffold;
- `NOTICE.md` scaffold;
- logging subsystem constants;
- CI or `scripts/test.sh`;
- formatter/linter only if already approved; do not add runtime code.

#### Definition of done

One documented command builds and tests the empty shell.

---

## 3. Date core — M1

### Task M1.1 — Implement validated value types

Files:

```text
SolarDate.swift
LunarDate.swift
YearMonth.swift
LocalTime.swift
```

Requirements:

- immutable public fields;
- `Hashable`, `Codable`, `Sendable`;
- safe validated creation;
- deterministic `Comparable` for `SolarDate` and `YearMonth`;
- no Foundation `Calendar.current` dependence.

Suggested API:

```swift
public static func valid(year: Int, month: Int, day: Int) -> SolarDate?
public init(validatingYear year: Int, month: Int, day: Int) throws
```

Tests:

- Gregorian leap years, including century behavior;
- invalid month/day;
- comparison across year/month boundaries;
- Codable round trip.

### Task M1.2 — Implement Gregorian/JDN conversion

Implement integer conversion in `GregorianJDN.swift`.

API:

```swift
public enum GregorianJDN {
    public static func jdn(for date: SolarDate) -> Int
    public static func solarDate(forJDN jdn: Int) throws -> SolarDate
}
```

Because production range begins in 1800, use one documented Gregorian formula consistently.

Tests:

- known JDN examples;
- every date across a broad range round-trips;
- adjacent civil dates differ by one JDN;
- 2000-01-01 JDN is asserted against an accepted convention and documented carefully (noon/midnight confusion).

### Task M1.3 — Add canonical Vietnamese date extraction

Implement:

```swift
public enum VietnamCalendarTime {
    public static let timeZone = TimeZone(secondsFromGMT: 25_200)!
    public static func solarDate(containing instant: Date) -> SolarDate
}
```

Tests must include instants immediately before and after UTC+7 midnight.

Do not use system-current time zone in this function.

---

## 4. Verified lunar data and engine — M2

### Task M2.1 — Establish reference-data provenance

Before generating production data:

- add `ReferenceData/README.md`;
- document source, retrieval/generation date, UTC+7 convention, supported range, checksum, and licensing note;
- retain any required attribution in `NOTICE.md`;
- add a script that verifies checksums.

Do not silently paste an unexplained integer array into the app.

### Task M2.2 — Build or import the generator

Create a development-only generator that emits:

```text
Sources/VietLunarCore/Generated/LunarYearTable.generated.swift
ReferenceData/vietnam-lunar-1800-2199.reference.json
ReferenceData/SHA256SUMS
```

Generator output must be sorted, deterministic, and contain records with:

- lunar year;
- Tết JDN;
- leap month number or zero;
- 12/13 month lengths;
- optional source metadata outside the runtime array.

Validation during generation:

- months only 29/30 days;
- 12 or 13 months;
- leap month in 1...12 or zero;
- Tết JDN strictly increasing;
- difference between successive Tết dates equals sum of year month lengths;
- sufficient sentinel data to convert 1800-01-01 and 2199-12-31.

### Task M2.3 — Implement table decoder

Implement `EncodedLunarYearRecord` and decoding helpers.

No heap allocation is required per conversion. A year record may expose a lightweight sequence or indexed method:

```swift
func monthLength(atSequentialIndex index: Int) -> Int
func logicalMonth(atSequentialIndex index: Int) -> (month: Int, isLeap: Bool)
func sequentialIndex(month: Int, isLeap: Bool) throws -> Int
```

Tests cover common and leap years, especially leap month 2 in 2004 and leap month 6 in 2025.

### Task M2.4 — Implement `LunarCalendarEngine`

Implement the protocol from the spec.

Required behavior:

- binary search by Tết JDN;
- strict range validation;
- exact leap-month mapping;
- exact month-length validation;
- typed errors;
- no astronomical floating point in production path;
- no locale/time-zone state.

Tests:

- golden examples;
- edge of each month;
- Tết boundaries;
- day 30 rejection in 29-day month;
- invalid leap flag;
- lower/upper range.

### Task M2.5 — Exhaustive conformance suite

Load the independent reference JSON only in tests. For every supported date:

```swift
XCTAssertEqual(try engine.lunarDate(for: solar), expected)
XCTAssertEqual(try engine.solarDate(for: expected), solar)
```

Also enumerate every valid lunar date from generated records and round-trip it.

Expected runtime should remain reasonable; use one test method per century or chunk if diagnostics become unwieldy.

### Task M2.6 — 2033 release gate

Add a named test suite:

```swift
final class LunarCalendar2033RegressionTests: XCTestCase
```

Assert the accepted Vietnamese UTC+7 sequence:

- 2033-11-22 = 01/11/2033 normal;
- 2033-12-21 = 30/11/2033 normal;
- 2033-12-22 = 01/11/2033 leap;
- 2034-01-19 = 29/11/2033 leap;
- 2034-01-20 = 01/12/2033 normal;
- round trips around every boundary.

Record at least two independent validations in `ReferenceData/README.md`, including a source that explicitly identifies the Vietnamese leap month. Do not derive expectations only from the production table being tested.

---

## 5. Can–Chi and snapshots — M3

### Task M3.1 — Implement typed stems and branches

Use enums with stable integer raw values:

```swift
public enum HeavenlyStem: Int, CaseIterable, Codable, Sendable { ... }
public enum EarthlyBranch: Int, CaseIterable, Codable, Sendable { ... }
```

Presentation names live in a formatter or computed Vietnamese display property.

Tests:

- exact order;
- all names and diacritics;
- Codable stability.

### Task M3.2 — Implement year/month/day calculations

Implement formulas from the spec.

Tests:

- 2004 year = Giáp Thân;
- lunar month 3/2004 = Mậu Thìn;
- day examples from golden vectors;
- every date plus 60 days repeats;
- every next day advances exactly one stem and one branch.

### Task M3.3 — Implement hour calculation and policy

Implement all 12 branch intervals and the policy abstraction.

Tests at:

```text
22:59, 23:00, 23:59, 00:00, 00:59, 01:00,
02:59, 03:00, ..., 21:00, 22:59
```

MVP default remains `civilMidnight`. Include an implementation path or tested placeholder for `startOfZiHour` only if it does not complicate the MVP; otherwise the enum may reject unsupported policy with a clear internal error until the future mode is accepted.

### Task M3.4 — Implement snapshot factory

A single captured instant produces:

- canonical solar date;
- lunar date;
- year/month/day/hour Can–Chi.

No multiple `Date()` reads.

Use `FixedClock` in tests around midnight and hour boundaries.

### Task M3.5 — Add traditional auspicious-hour reference

When this scope is explicitly accepted, add a pure Core lookup from the selected civil date's day branch to six traditional two-hour intervals. Keep it offline and label it as cultural reference only; do not infer suitability for a person, activity, or outcome.

Tests:

- all 12 day branches map to exactly six distinct hour branches;
- all twelve civil ranges are exact, including Tý `23:00–00:59`;
- a known day Can–Chi vector selects the expected six intervals;
- selected-day UI exposes the labelled reference text accessibly.

---

## 6. Month grid domain — M4

### Task M4.1 — Implement `MonthGridBuilder`

Input:

```swift
YearMonth
WeekStart
Today SolarDate
LunarCalendarCalculating
```

Output: exactly 42 cells.

Rules:

- Gregorian grid;
- includes leading/trailing dates;
- lunar date in each cell;
- today and in-month flags;
- errors only at supported range boundaries;
- no UI types in core.

Tests:

- month beginning every weekday;
- February common/leap years;
- Monday/Sunday week start;
- month spanning lunar year boundary;
- month containing leap-month boundary;
- exactly 42 unique, consecutive solar dates.

### Task M4.2 — Add formatters

Create stateless or safely cached formatting helpers for:

- compact menu title;
- full Gregorian date in Vietnamese;
- lunar date normal/leap;
- Can–Chi display;
- cell accessibility label.

Tests should assert output strings, including Vietnamese diacritics and leap markers.

---

## 7. Menu-bar UI — M5

### Task M5.1 — Wire live menu title

Replace placeholder label with snapshot-derived text.

Requirements:

- default `dd/MM ÂL`;
- accessibility label is full text;
- preference changes update immediately;
- no timer introduced yet beyond explicit state refresh.

### Task M5.2 — Build calendar popover

Implement:

- header;
- month navigation;
- 42-cell grid;
- selected-day detail;
- Today, Settings, Quit;
- dark/light mode;
- range boundary state.

Keep views small and avoid per-cell observable objects.

### Task M5.3 — Keyboard and accessibility

Add:

- arrow-key day navigation;
- month keyboard shortcuts;
- Escape close where possible;
- VoiceOver labels;
- selected/today semantics;
- tooltips for controls.

Run Accessibility Inspector manually and note remaining issues.

### Task M5.4 — UI smoke tests

Automate what is stable:

- open popover;
- find today header;
- navigate month;
- click Today;
- open Settings.

Avoid brittle screenshot pixel assertions for standard system materials.

---

## 8. Lifecycle and low-energy refresh — M6

### Task M6.1 — Implement boundary calculation as a pure function

API example:

```swift
public protocol BoundaryCalculating: Sendable {
    func nextBoundary(
        after instant: Date,
        requirements: RefreshRequirements
    ) throws -> Date
}
```

Test canonical midnight, minute boundary, hour-branch boundaries, daylight/time-zone differences for system clock display, and exact equality behavior.

### Task M6.2 — Implement one-shot scheduler

Requirements:

- one active scheduled task maximum;
- cancellation on replacement/deinit;
- tolerance where acceptable;
- callback hops to `@MainActor` safely;
- fake scheduler for tests.

Do not use `Timer.publish(every: 1, ...)`.

### Task M6.3 — Implement lifecycle source

Observe:

- day changed;
- system clock changed;
- system time zone changed;
- app active;
- wake from sleep;
- popover open.

Map all to typed lifecycle events. `AppState` coalesces and refreshes.

### Task M6.4 — Verify idle behavior

Manual/instrumented check with default preferences:

- close popover;
- wait five minutes;
- no repeating timer firing;
- no logs every second/minute;
- CPU effectively idle;
- one future one-shot boundary only.

Record findings in `docs/performance-baseline.md`.

---

## 9. Settings and login item — M7

### Task M7.1 — Implement typed preferences store

Add:

- defaults;
- load/save;
- change stream;
- schema version/migration path;
- tests with isolated `UserDefaults` suite.

Do not persist derived title or login-item truth.

### Task M7.2 — Build Settings UI

Controls:

- title format;
- Gregorian date in title;
- Can–Chi in title;
- clock in title;
- week start;
- 24-hour clock;
- Launch at Login;
- About/attribution.

Toggling live clock must change refresh requirements and timer granularity.

### Task M7.3 — Implement `SMLoginItemService`

Map every relevant `SMAppService.Status` to domain status.

Behavior:

- register/unregister;
- status refresh on Settings appearance and app activation;
- approval-required message;
- open System Settings;
- errors shown without crash.

Unit-test status mapping. Manual-test real registration in a signed app under `/Applications`.

### Task M7.4 — Finalize Dock/accessory behavior

Verify:

- no Dock icon;
- menu item persists;
- Settings focuses;
- login launch starts quietly without opening popover;
- app can always be quit from menu.

---

## 10. Release hardening — M8

### Task M8.1 — Full test matrix

Run:

- unit tests;
- exhaustive conformance;
- UI smoke tests;
- Release build;
- clean install/manual checklist;
- login-item checklist;
- sleep/wake and clock-change checklist;
- offline/network checklist.

### Task M8.2 — Performance baseline

Record:

- cold launch;
- first/subsequent popover open;
- RSS after 30 seconds;
- idle CPU/wakeups over five minutes;
- full-range conversion time;
- 42-cell build time;
- app bundle size.

If RSS > 60 MB or sustained idle work exists, profile before release. Do not immediately rewrite the core; the likely fallback is only an AppKit shell.

### Task M8.3 — Privacy and release metadata

Add:

- privacy statement: all data local, no network/analytics;
- attribution/license notices;
- supported range and historical caveat;
- version/build display;
- signing/notarization instructions appropriate to distribution;
- reproducible build/test commands.

### Task M8.4 — Acceptance review

Check every checkbox in `VietLunar_SPEC.md` section 19. Any unchecked item requires either a fix or an accepted ADR/waiver.

---

## 11. Future event implementation plan — do not execute in MVP

### Task E0 — Stabilize event domain contracts

Add domain types and recurrence policies exactly as specified. Unit-test Codable compatibility and validation. No database/UI yet.

### Task E1 — SQLite actor and migrations

Implement:

- database path;
- connection actor;
- schema v1;
- migrations via `PRAGMA user_version`;
- transactions;
- CRUD repository;
- corruption/error mapping;
- temporary-directory integration tests.

### Task E2 — One-time event CRUD

Implement:

- Gregorian/lunar one-time schedules;
- all-day/timed;
- title/notes;
- create/edit/delete/duplicate;
- occurrence resolution;
- dots/list in calendar popover.

### Task E3 — Notifications

Implement contextual permission request and one-time reminders. The DB remains source of truth. Add deterministic request identifiers and reconciliation tests with a fake notification center.

### Task E4 — Recurrence

Implement bounded expansion for daily/weekly/monthly/yearly rules. Add lunar yearly rules with explicit leap-month and missing-day policies. Exhaustive boundary tests are required.

### Task E5 — Export/import

Versioned JSON export, validation, duplicate policy, atomic import, and local backup. No sync.

---

## 12. Suggested commands

Adapt scheme/destination names to the actual project and document them in README.

```bash
# List schemes
xcodebuild -list -project VietLunar.xcodeproj

# Debug build
xcodebuild \
  -project VietLunar.xcodeproj \
  -scheme VietLunar \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

# Unit tests
xcodebuild \
  -project VietLunar.xcodeproj \
  -scheme VietLunar \
  -configuration Debug \
  -destination 'platform=macOS' \
  test

# Release build
xcodebuild \
  -project VietLunar.xcodeproj \
  -scheme VietLunar \
  -configuration Release \
  -destination 'platform=macOS' \
  clean build

# Verify checked-in reference data
./scripts/verify_reference_data.sh

# Regenerate calendar table; exact command depends on generator target
swift run CalendarTableGenerator \
  --range 1800-01-01...2199-12-31 \
  --timezone +07:00 \
  --output Sources/VietLunarCore/Generated/LunarYearTable.generated.swift
```

---

## 13. Pull-request completion template

```markdown
## Scope
- Milestone/task IDs:
- User-visible change:

## Calendar conventions
- Calculation zone: UTC+7
- Supported range affected:
- Can–Chi boundary policy affected: yes/no

## Files changed
- ...

## Tests run
- `...` — passed/failed
- Exhaustive date count: ...

## Performance
- Relevant measurement before/after:

## Data/provenance
- Generated data changed: yes/no
- Checksum changed: yes/no
- Reference source/approval:

## Risks / follow-up
- ...
```

---

## 14. Stop conditions

Codex must stop and report rather than guess when:

- two independent references disagree on a lunar date;
- generated table invariants fail;
- 2033 expected output has no recorded provenance;
- a requested date lies outside the supported range;
- a runtime dependency appears necessary;
- login-item behavior differs between debug and signed installed builds;
- a proposed optimization weakens correctness or test coverage.

A stop condition does not justify abandoning all work: complete unaffected tasks, isolate the discrepancy, and report exact inputs/outputs and candidate causes.
