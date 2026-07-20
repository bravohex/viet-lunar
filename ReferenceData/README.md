# VietLunar reference-data provenance

## Scope and convention

This directory holds development/test reference material used to generate and validate the immutable production lunar-year table.

- Supported Gregorian range: `1800-01-01...2199-12-31`.
- Calendar model: modern astronomical Vietnamese lunisolar calendar.
- Calculation zone: fixed UTC+7 / meridian 105°E.
- Dates before 1976 are proleptic modern results, not a reconstruction of every historically official regional calendar.
- Retrieval/provenance baseline date: 2026-07-20.

## Source roles

The machine-readable source inventory is `source-catalog.json`.

1. Hồ Ngọc Đức’s Vietnamese calendar rules define the calendar rules, UTC+7/Hanoi convention, documented 1984/2004 examples, the distinction between official and proleptic calendars, and the historical correction of the 2033 leap-month calculation.
2. The Hồ Ngọc Đức JavaScript calendar is valid for 1800-2199, but its header limits permission to personal, non-commercial use. Its code/data is not copied or approved as a release oracle without compatible distribution scope or additional permission.
3. *Calendrical Calculations* is an independent algorithmic reference. VietLunar must use an original implementation or separately licensed software; it must not copy the accompanying software package without permission.
4. Hermetic Systems material is a secondary independent cross-check for the Vietnamese reference longitude/time-zone behavior and rare leap-month cases. It is not a production dependency.
5. The MIT-licensed `luc-nham/lunar-calendar` implementation at the pinned revision is an independent candidate. It matches the required 2033 sequence but has 13,028 full-range mismatches, so it is rejected as the exhaustive oracle. See `../docs/independent-oracle-audit.md`.

## Licensing decision

No third-party calendar source code or prepared table is currently redistributed by VietLunar. Public pages are used only to document rules and compare outputs. Before any copied/transformed dataset is added, its exact version, license, attribution, and redistribution permission must be reviewed and recorded here and in `NOTICE.md`.

The planned production generator will contain an original Swift implementation of published calendrical rules. Generated output will include its input metadata and checksum. Independent comparison data must remain test-only.

## Generated artifacts

Task M2.2 adds:

- `vietnam-lunar-1800-2199.reference.json` with 146,097 compact rows;
- 402 generated runtime records for sentinel lunar years 1799-2200 under `Sources/Core/Generated/`;
- updated `SHA256SUMS` containing every committed machine-readable reference artifact.

Both artifacts are emitted by the same original Swift astronomical generator. They are deterministic candidate inputs, but they are not independent of one another. The JSON must not be used as the sole conformance oracle for the generated production table; M2.5 remains open until an independent dataset has been compared exhaustively.

## Checksum verification

Run:

```bash
./scripts/verify_reference_data.sh
```

The command verifies byte-level SHA-256 checksums from `SHA256SUMS`. Regeneration must be deterministic; an intentional data update must update checksums in the same reviewed task.

## Release gates

- Exhaustive comparison for every supported solar date is still required.
- Exhaustive valid lunar-date round trips are still required.
- The accepted 2033 sequence must be validated by at least two independent sources, including one that explicitly identifies the Vietnamese leap month as month 11.
- A production table must never be its own only test oracle.
- A permissive license alone is insufficient: an independent candidate must also match or explain every supported-date discrepancy before it can close M2.5.
