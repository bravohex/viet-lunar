# Vietnam holiday data generator

This development tool produces `App/Resources/Holidays/vietnam.ics` for **2000–2050**. The app has no Node.js dependency and never fetches calendar data at runtime.

```sh
cd Tools/Holidays
npm ci
npm test
npm run generate
npm run check
```

Use Node.js 22 or newer. `npm ci` uses the committed lockfile, disables lifecycle scripts via `.npmrc`, and pins the Vietnamese lunar engine (`date-chinese` 2.1.4). Generation is deterministic and independent of the computer's timezone. `--check` compares bytes without writing the bundled file.

## Source and modifications

`source.json` records the exact fork commit, package version, snapshot date, checksums and exclusions. `vendor/VN.yaml` is an unmodified copy from `bravohex/date-holidays` at that commit. `vendor/names.json` contains only Vietnamese/English names for the three shared rules referenced by VN.yaml, extracted from that commit's `data/names.yaml`. The expanded Vietnam rules are from the fork, not an upstream release.

The generator uses the Vietnamese calendar in `Asia/Ho_Chi_Minh`, emits explicit all-day dates with stable UIDs, preserves `public` / `observance`, and respects `since` / `prior to` conditions. ICS text is escaped and UTF-8 lines are folded at 75 octets. The calendar is bounded by the app's 1 MiB / 20,000 event limits.

The source's generic five-day Tet break is deliberately excluded: the position of those days varies by annual announcement and employer. Tet day and the separate eve observance remain. No compensatory days, additional National Day leave, employer-specific leave or workday swaps are inferred. This is a holiday/commemoration calendar, **not an official leave schedule**. Rules without a historical start date are projected into earlier years; the data is not a reconstruction of historical law. Future dates reflect the pinned rules, which may change.

When refreshing the source, review VN rule changes and primary-source references first; update the snapshot, relevant shared names, source commit/date and SHA-256 hashes together. Review the exclusion policy and dependency versions, regenerate, and run both Node tests and the app's full functional tests. Swift tests compare all lunar holiday dates with VietLunar's own engine. Never resolve a mismatch by silently changing one date or weakening an assertion.

## Attribution and license

Holiday data is adapted from **date-holidays contributors** and **Wikipedia contributors**, especially [Public holidays in Vietnam](https://en.wikipedia.org/wiki/Public_holidays_in_Vietnam), under [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/). See `vendor/date-holidays-LICENSE` for the source license and attribution list. Source: https://github.com/commenthol/date-holidays; expanded VN rules: https://github.com/bravohex/date-holidays.

The generated ICS is an adaptation under the same CC BY-SA 3.0 license. It embeds attribution, license URL, source commit and the removal of projected leave periods in `X-WR-CALDESC`. Retain these notices when redistributing data. The repository's MIT license continues to apply to VietLunar code; it does not replace the holiday data license.
