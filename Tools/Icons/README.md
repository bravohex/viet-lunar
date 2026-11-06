# Lucide assets for VietLunar

All shipped interface symbols and the application glyph come from **lucide-static 1.69.0**. The npm lockfile pins the source archive and **@resvg/resvg-js 2.6.2** used for build-time PNG rendering. No JavaScript, icon font, renderer or third-party runtime is bundled in the macOS app.

```sh
cd Tools/Icons
npm ci
npm run generate
npm run check
```

Use Node.js 22 or newer. Lifecycle scripts are disabled. The generator outputs the selected vector SVG imagesets, ten macOS AppIcon PNG renditions and the complete upstream license notice. `--check` regenerates in memory and compares all 32 output files byte-for-byte without writing. CI runs this check; application tests also verify the compiled asset catalog contains every expected icon and no old `VL*` custom assets.

| Use | Official Lucide icon |
| --- | --- |
| App and menu bar | `calendar-days` |
| Previous / next month | `chevron-left` / `chevron-right` |
| Today | `calendar-check` |
| Settings / about | `settings` / `info` |
| Quit | `power` |
| Holiday / observance | `flag` / `bookmark` |
| Warning / error | `triangle-alert` |

SVG geometry and stroke width are unchanged. `currentColor` becomes black at asset generation; Xcode/SwiftUI template rendering supplies the UI's foreground color in light, dark and disabled states. Decorative icons are hidden from accessibility, while the existing button labels and day text remain accessible. The menu-bar image uses an 18-point template to fit the native status item.

The app icon uses the same unmodified `calendar-days` glyph in white on a red (`#C53630`) rounded macOS tile with transparent margins. The tile is presentation framing; no custom illustrated glyph remains. AppIcon files range from 16 px to 1024 px and include all ten standard macOS renditions.

## Attribution

[Lucide](https://lucide.dev), copyright (c) 2026 Lucide Icons and Contributors, is distributed under the ISC license, with the Feather notices included in the upstream package. The complete notice is copied to `App/Resources/Lucide-LICENSE.txt` and included in the application bundle. Retain it when distributing the app or extracted assets.

The former custom kit review under `docs/icon-kit-review.md` is historical; the seven custom PDF imagesets and old app-icon PNG artwork have been removed or replaced.
