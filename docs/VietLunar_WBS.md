# VietLunar — Work Breakdown Structure

**Cập nhật gần nhất:** 2026-07-20

**Phạm vi:** MVP macOS theo `VietLunar_SPEC.md` và `VietLunar_CODEX_PLAN.md`

**Nguồn trạng thái chính:** tài liệu này

## 1. Quy ước thực thi

- Mỗi task được triển khai, kiểm thử và cập nhật trạng thái trong đúng một commit riêng.
- Không đánh dấu `Hoàn thành` nếu definition of done hoặc kiểm thử bắt buộc của task chưa đạt.
- Không làm các task `E0...E5` về event trong MVP.
- Không làm yếu test accuracy để hợp thức hóa kết quả.
- Dữ liệu lịch âm production phải có provenance, checksum và đối chiếu độc lập.
- Các kiểm tra cần app đã ký, cài trong `/Applications`, Accessibility Inspector hoặc Instruments được ghi là `Chờ kiểm tra thủ công` cho đến khi có bằng chứng thật.

Trạng thái:

- `Hoàn thành`: code, test/build và tài liệu task đã đạt.
- `Đang làm`: task đang được triển khai.
- `Chờ`: chưa bắt đầu hoặc đang chờ dependency.
- `Bị chặn`: có stop condition cụ thể, không được suy đoán để đi tiếp.
- `Chờ kiểm tra thủ công`: phần tự động đã đạt nhưng cần kiểm chứng trên app đã cài/ký hoặc công cụ GUI.

## 2. Kết luận phân tích đầu vào

1. Repo ban đầu chỉ có README, spec, plan, prompt và curated test vectors; chưa có Xcode project hay Swift source.
2. `VietLunar_SPEC.md` là hợp đồng kỹ thuật; `VietLunar_CODEX_PLAN.md` xác định thứ tự task; `VietLunar_CODEX_PROMPT.md` mô tả quy trình vận hành.
3. `VietLunar_TEST_VECTORS.json` chỉ là golden test có chọn lọc, không thay thế exhaustive reference data cho 1800-2199.
4. MVP gồm 34 task từ M0.1 đến M8.4. Các task event E0-E5 nằm ngoài phạm vi.
5. Release gate khó nhất là M2.5/M2.6: cần dữ liệu tham chiếu độc lập, provenance rõ ràng và chuỗi năm 2033 được xác nhận bởi ít nhất hai nguồn.
6. Các phần không phụ thuộc reference data có thể triển khai và kiểm thử độc lập trước khi đóng release gate.

## 3. WBS MVP

| Task | Nội dung | Dependency chính | Trạng thái | Commit | Bằng chứng |
|---|---|---|---|---|---|
| A0 | Phân tích tài liệu và tạo WBS thực thi | — | Hoàn thành | commit này | Đã đọc đầy đủ spec, plan, prompt, test vectors; knowledge graph hợp lệ |
| A1 | Ổn định deterministic Xcode project generation | M0.1 | Hoàn thành | commit này | Hai lần generate liên tiếp có checksum byte-identical |
| A2 | Khóa UUID cho target dependency trùng cấu trúc | A1 | Hoàn thành | commit này | Ba lần generate liên tiếp byte-identical sau khi project mở rộng |
| A3 | Ổn định lifecycle burst coalescing | M6.3 | Hoàn thành | commit này | Debounce one-shot 10 ms; test lặp 3 lần đạt |
| A4 | Xác minh signed Release idle behavior | M6.4 | Hoàn thành | commit này | Time Profiler 300,84s; +0,01s CPU; không app-owned loop |
| B0 | Ghi nhận independent-reference blocker | M2.4 | Hoàn thành | commit này | Không dùng candidate JSON làm oracle hoặc sao chép data chưa rõ license |
| M0.1 | Tạo Xcode project, app/core/infrastructure/test targets | A0 | Hoàn thành | commit này | 6 targets, shared scheme, Debug build và 3 test bundles đạt |
| M0.2 | Tạo `MenuBarExtra`, ẩn Dock, Settings và Quit | M0.1 | Hoàn thành | commit này | Build/test đạt; LSUIElement=true; app bundle chạy thật và hiện `ÂL` trên menu bar |
| M0.3 | Bổ sung chuẩn repo, logging, README/NOTICE, test script | M0.2 | Hoàn thành | commit này | `.gitignore` đầy đủ; `./scripts/test.sh` build và test đạt |
| M1.1 | Value types được validate | M0.3 | Hoàn thành | commit này | 4 immutable types; validation/Comparable/Codable tests đạt |
| M1.2 | Gregorian/JDN conversion | M1.1 | Hoàn thành | commit này | Known JDN, adjacent dates và 146.097-day round trip đạt |
| M1.3 | Trích xuất ngày theo UTC+7 | M1.1 | Hoàn thành | commit này | Fixed UTC+7; before/after midnight và year-boundary tests đạt |
| M2.1 | Thiết lập provenance cho reference data | M1 | Hoàn thành | commit này | Source catalog, license policy và checksum verification đạt |
| M2.2 | Generator và generated/reference outputs | M2.1 | Hoàn thành | commit này | 402 records, 146.097 rows, deterministic checksums và invariants đạt |
| M2.3 | Lunar year record decoder | M2.2 | Hoàn thành | commit này | Compact bitset decoder; 2004/2025 leap mapping tests đạt |
| M2.4 | `LunarCalendarEngine` hai chiều | M2.3 | Hoàn thành | commit này | Binary-search engine; golden/all-month boundary/error tests đạt |
| M2.5 | Exhaustive conformance suite | M2.4 | Bị chặn | — | Candidate JSON không độc lập; cần approved independent dataset |
| M2.6 | Release gate năm 2033 | M2.5 | Bị chặn | — | Chờ M2.5 và bằng chứng nguồn độc lập được lưu trong repo |
| M3.1 | Typed Heavenly Stem/Earthly Branch | M1 | Hoàn thành | commit này | Raw values ổn định; đúng thứ tự/tên tiếng Việt; Codable tests đạt |
| M3.2 | Can-Chi năm/tháng/ngày | M3.1, M1.2 | Hoàn thành | commit này | Golden vectors và exhaustive 146.097 ngày/chu kỳ 60 đạt |
| M3.3 | Can-Chi giờ và boundary policy | M3.2 | Hoàn thành | commit này | 12 khoảng giờ, 1.440 phút và hai boundary policies đạt |
| M3.4 | `CalendarSnapshotFactory` | M2.4, M3.3, M1.3 | Hoàn thành | commit này | Một instant tạo solar/lunar và 4 Can-Chi; midnight tests đạt |
| M4.1 | `MonthGridBuilder` 42 ô | M2.4 | Hoàn thành | commit này | 42 ngày liên tiếp; week starts/leap/boundary tests đạt |
| M4.2 | Vietnamese formatters | M3.4, M4.1 | Hoàn thành | commit này | Exact strings, leap marker, weekday và VoiceOver tests đạt |
| M5.1 | Menu title từ live snapshot | M3.4, M4.2 | Hoàn thành | commit này | Live snapshot title, 5 formats, full accessibility label; app chạy thật |
| M5.2 | Calendar popover và month navigation | M4.1, M5.1 | Hoàn thành | commit này | Header, grid 6×7, detail/footer/range navigation; app chạy thật |
| M5.3 | Keyboard và accessibility | M5.2 | Hoàn thành | `d7d6113` + commit này | AX tree xác nhận label/value/selected state trong flow thật |
| M5.4 | UI smoke tests | M5.3 | Hoàn thành | commit này | Launch/open/navigate/today/settings end-to-end đạt |
| M6.1 | Pure next-boundary calculation | M3.3 | Hoàn thành | commit này | Midnight/hour/minute/DST/exact-equality tests đạt |
| M6.2 | One-shot scheduler | M6.1 | Hoàn thành | commit này | Single task, replacement/cancel/deinit/tolerance tests đạt |
| M6.3 | Lifecycle source và coalesced refresh | M6.2, M5.1 | Hoàn thành | commit này | 5 system + popover/boundary events; coalescing tests đạt |
| M6.4 | Xác minh idle behavior | M6.3 | Hoàn thành | `2c17ca5` + A4 | Signed Release 5-minute idle đạt; transient RSS chuyển M8.2 |
| M7.1 | Typed preferences store | M0.3 | Hoàn thành | commit này | Versioned root, v0 migration/change stream; toàn scheme 88/88 tests |
| M7.2 | Settings UI | M7.1, M5.1, M6.3 | Hoàn thành | commit này | Live controls, minute-boundary clock, isolated UI flow; 92/92 tests |
| M7.3 | `SMLoginItemService` | M7.2 | Bị chặn | commit này | Code/93 tests/Developer ID Release đạt; chưa cài `/Applications` và register thật |
| M7.4 | Hoàn thiện Dock/accessory behavior | M7.3 | Hoàn thành | commit này | Signed Release launch, accessory policy, persistent status item/UI flow đạt |
| M8.1 | Chạy full test matrix | M2-M7 | Bị chặn | commit này | 95/95 + exhaustive round-trip đạt; independent/manual gates còn mở |
| M8.2 | Ghi performance baseline | M8.1 | Chờ | — | Launch, popover, RSS, idle, conversion, bundle size |
| M8.3 | Privacy, attribution và release metadata | M8.1 | Chờ | — | Privacy/range/notarization/reproducible commands |
| M8.4 | Acceptance review | M8.2, M8.3 | Chờ | — | Rà toàn bộ checklist spec mục 19 |

## 4. Release gates đang mở

| Gate | Trạng thái ban đầu | Điều kiện đóng |
|---|---|---|
| Reference-data license/provenance | Chưa xác minh | Ghi rõ nguồn, phiên bản/commit, ngày lấy, license và checksum |
| Exhaustive 1800-2199 reference | Chưa có trong repo | Có independent JSON và so sánh mọi ngày |
| 2033 independent validation | Curated vectors có URL nhưng chưa lưu bằng chứng độc lập | Lưu provenance của ít nhất hai nguồn, một nguồn nói rõ leap month 11 Việt Nam |
| Signed login item | Chưa có app | Build ký, copy `/Applications`, kiểm tra enable/disable/approval |
| Accessibility | Chưa có UI | Chạy Accessibility Inspector và ghi issue còn lại |
| Idle energy/performance | Chưa có app | Đo app Release khi popover đóng trong năm phút |

## 5. Nhật ký hoàn thành

### A0 — Phân tích tài liệu và tạo WBS

- Đã đọc đầy đủ 2.738 dòng tài liệu/fixture ban đầu.
- Đã xác nhận repo chưa có implementation.
- Đã tách MVP M0-M8 khỏi future event E0-E5.
- Đã ghi rõ các gate không được suy đoán, đặc biệt provenance và 2033.

### M0.1 — Tạo project và targets

- Tạo native Xcode project bằng generator phát triển có tính deterministic; không thêm runtime dependency.
- Tạo app, core framework, infrastructure framework, hai unit-test bundles và một UI-test bundle.
- Dùng deployment target macOS 13.0, Swift 6 và strict concurrency.
- Giữ tên thư mục vật lý ngắn theo trách nhiệm: `Sources/Core`, `Sources/Infrastructure`, `Tests/CoreTests`, `Tests/InfrastructureTests`, `Tests/UITests`.
- `xcodebuild -list`, Debug build và test scheme đều đạt trên Xcode 26.0.1.

### M0.2 — Menu-bar application shell

- Thay cửa sổ app mặc định bằng `MenuBarExtra` kiểu window với nhãn `ÂL`.
- Thêm popover placeholder, phiên bản, Settings và Quit bằng tiếng Việt.
- Bật `LSUIElement=true` để ẩn Dock icon và menu ứng dụng thông thường.
- Sửa build phase để nhúng cả hai framework nội bộ vào app bundle; kiểm tra trực tiếp app chạy được ngoài test runner.
- Debug build, unit/UI test scheme và kiểm tra Info.plist đều đạt; ảnh chụp thực tế xác nhận mục `ÂL` xuất hiện trên menu bar.

### M0.3 — Chuẩn repository

- Mở rộng `.gitignore` cho macOS, Xcode/DerivedData, Swift caches, IDE state, local secrets, logs và artifact phân tích.
- Cập nhật README với yêu cầu môi trường, kiến trúc, quy ước lịch và lệnh build/test.
- Thêm NOTICE scaffold để khóa yêu cầu attribution/license trước khi đưa reference data vào repo.
- Thêm logging subsystem/category constants bằng `OSLog`.
- Thêm `scripts/test.sh`; lệnh duy nhất này đã chạy thành công `xcodebuild -list`, Debug build và toàn bộ test scheme.

### M1.1 — Validated date/time value types

- Thêm `SolarDate`, `LunarDate`, `YearMonth` và `LocalTime` với immutable public fields.
- Tất cả type đều `Hashable`, `Codable`, `Sendable`; `SolarDate`, `YearMonth` và `LocalTime` có thứ tự deterministic.
- Public factories/throwing initializers validate component; custom Codable decoding không thể tạo trạng thái ngày sai.
- Test leap-year bao gồm quy tắc thế kỷ, input lỗi, boundary comparison và Codable round trip.
- Toàn scheme đạt 10/10 tests sau task.

### A1 — Deterministic Xcode project generation

- Phát hiện UUID của `.pbxproj` thay đổi sau mỗi lần chạy generator dù input không đổi.
- Chuẩn hóa UUID trước khi lưu project.
- Chạy generator hai lần liên tiếp và xác nhận checksum của `project.pbxproj` cùng shared scheme không thay đổi.

### M1.2 — Gregorian/JDN conversion

- Thêm chuyển đổi hai chiều proleptic Gregorian ↔ Julian Day Number bằng số nguyên.
- Ghi rõ convention `2000-01-01 = JDN 2.451.545` để tránh nhầm noon/midnight numbering.
- Kiểm tra known vectors 1970, 2000, 2004; các boundary liền ngày; typed error cho JDN ngoài miền value type.
- Round-trip toàn bộ 146.097 ngày trong khoảng production 1800-2199.
- Toàn scheme đạt 14/14 tests sau task.

### M1.3 — Canonical UTC+7 date extraction

- Thêm `VietnamCalendarConvention` và `VietnamCalendarTime` với fixed offset +07:00.
- Dùng Gregorian `Calendar` được khởi tạo explicit; không dùng `Calendar.current` hoặc user-selected calendar.
- Test ngay trước và đúng nửa đêm UTC+7, cùng boundary đổi năm.
- Toàn scheme đạt 18/18 tests sau task.

### M2.1 — Reference-data provenance

- Tạo `ReferenceData/README.md` và source catalog machine-readable với ngày truy xuất, UTC+7/105°E convention, range và vai trò từng nguồn.
- Ghi rõ Hồ Ngọc Đức JavaScript/prepared data chỉ là comparison oracle cho đến khi xác minh được license; không sao chép code/data vào production.
- Ghi nhận *Calendrical Calculations* và Hermetic Systems ở vai trò independent algorithmic/secondary cross-check.
- Cập nhật NOTICE và thêm SHA-256 manifest.
- `scripts/verify_reference_data.sh` xác minh `source-catalog.json: OK`; toàn Xcode scheme vẫn đạt 18/18 tests.

### M2.2 — Lunar table generator

- Thêm original Swift astronomical generator, fixed UTC+7, không có third-party dependency.
- Generator kiểm tra month length chỉ 29/30 ngày, 12/13 tháng, đúng số leap month, Tết tăng nghiêm ngặt, year-length sum và sentinel coverage.
- Sinh 402 lunar-year records 1799-2200 và 146.097 reference rows cho 1800-2199.
- Curated sentinels 1984, 2004, 2025 và 2033 được kiểm tra trong generator.
- Hai lần generate liên tiếp cho checksum byte-identical; checksum verification và toàn Xcode scheme đều đạt.
- Reference JSON cùng production table đến từ cùng generator nên M2.5 vẫn chưa được xem là independent conformance.

### M2.3 — Encoded lunar-year decoder

- Thêm compact `EncodedLunarYearRecord` với `Int32` Tết JDN, `UInt8` leap month và `UInt16` month-length bitset.
- Hỗ trợ month length lookup, sequential index ↔ logical normal/leap month mà không cấp phát heap cho mỗi conversion.
- Generated table dùng trực tiếp typed records và debug invariants.
- Test common year, nhuận tháng 2/2004, nhuận tháng 6/2025, invalid leap flag/index và invalid bit mask.
- Checksum verification đạt; toàn scheme đạt 23/23 tests.

### M2.4 — Table-based lunar engine

- Thêm public `LunarCalendarCalculating`, typed error model và immutable `LunarCalendarEngine`.
- Solar-to-lunar dùng binary search theo Tết JDN và tối đa 13 month-length steps; lunar-to-solar dùng exact sequential mapping.
- Production path chỉ dùng integer/JDN/generated table, không dùng astronomical floating point, locale hoặc time-zone state.
- Test toàn bộ curated vectors, Tết boundary, month length/leap metadata, invalid day/leap/range và hai đầu supported range.
- Test ngày đầu/cuối của mọi generated lunar month round-trip khi nằm trong production range.
- Checksum verification đạt; toàn scheme đạt 31/31 tests.

### B0 — Independent-reference blocker

- `vietnam-lunar-1800-2199.reference.json` và generated production table được sinh từ cùng original Swift generator; chúng chỉ chứng minh deterministic/self-consistency, không phải independence.
- Hồ Ngọc Đức JavaScript/prepared tables chưa có redistribution license rõ ràng trong các trang đã kiểm tra, nên không sao chép vào repo để làm test oracle.
- M2.5 chỉ được mở lại khi có approved independent dataset hoặc original independent implementation đã được review và có provenance riêng.
- M2.6 chờ M2.5, đồng thời cần lưu bằng chứng của ít nhất hai nguồn độc lập cho chuỗi leap month 11 năm 2033.
- Theo stop conditions, các task M3/M4/M6/M7 không phụ thuộc independent data vẫn tiếp tục; release acceptance M8 chưa thể đóng.

### M3.1 — Typed Heavenly Stem/Earthly Branch

- Thêm `HeavenlyStem` gồm 10 can và `EarthlyBranch` gồm 12 chi với `Int` raw value tường minh, `CaseIterable`, `Codable`, `Sendable`.
- Tên hiển thị tiếng Việt được tách khỏi raw value, giữ nguyên thứ tự chuẩn và chuẩn hóa `Tỵ` theo spec.
- Test khóa thứ tự, đầy đủ dấu tiếng Việt, JSON raw value ổn định và từ chối giá trị ngoài enum.
- Reference checks đạt; toàn scheme đạt 35/35 tests.

### M3.2 — Can-Chi năm/tháng/ngày

- Thêm `StemBranch` và `CanChiCalculator` thuần Core, dùng đúng các công thức năm âm lịch, tháng âm lịch và ngày theo JDN trong spec.
- Leap month kế thừa Can–Chi của tháng thường cùng số; `floorMod` xử lý đúng cả đầu vào âm trong test.
- Golden vectors 2004 đạt: năm `Giáp Thân`, tháng 3 `Mậu Thìn`, ngày 2004-04-19 `Mậu Thìn` tại JDN 2.453.115.
- Kiểm tra exhaustive toàn bộ 146.097 ngày 1800–2199: ngày kế tiếp tăng đúng một can/một chi và sau 60 ngày lặp lại.
- Toàn scheme đạt 40/40 tests.

### M3.3 — Can-Chi giờ và boundary policy

- Thêm `CanChiDayBoundaryPolicy` có mặc định ổn định là `civilMidnight` và đường triển khai đầy đủ cho `startOfZiHour`.
- `CanChiCalculator` tính chi giờ từ 12 khoảng hai giờ và can giờ từ can ngày hiệu lực theo policy.
- Test toàn bộ boundary được nêu trong spec, đủ 12 chi và exhaustive cả 1.440 phút trong ngày.
- Test xác nhận giờ Tý bị tách can tại nửa đêm theo mặc định; với `startOfZiHour`, 23:00 dùng can của ngày kế tiếp.
- Reference checks đạt; toàn scheme đạt 45/45 tests.

### M3.4 — CalendarSnapshotFactory

- Thêm `Clock`, `SystemClock`, `FixedClock` và `LocalDateTime` để tách absolute instant khỏi civil components UTC+7.
- `CalendarSnapshotFactory` chỉ gọi `clock.now()` một lần rồi tạo đồng bộ solar date, lunar date và Can-Chi năm/tháng/ngày/giờ.
- Test bằng `FixedClock` ngay trước/sau nửa đêm Việt Nam, test `startOfZiHour`, và spy clock xác nhận chính xác một lần đọc.
- Reference checks đạt; toàn scheme đạt 50/50 tests.

### M4.1 — MonthGridBuilder 42 ô

- Thêm `WeekStart`, `MonthGridCell` và `MonthGridBuilder` thuần Core; mỗi grid luôn có đúng 42 ngày Gregorian liên tiếp với lunar date tương ứng.
- `id` suy ra trực tiếp từ `SolarDate`; không có per-cell observable state hoặc phụ thuộc UI.
- Test tháng bắt đầu ở đủ bảy weekday, tuần bắt đầu Thứ Hai/Chủ Nhật, February thường/nhuận, today/in-month flags, Tết 1984 và tháng nhuận 2004.
- Hai grid chạm ngoài dải 1800–2199 trả typed `unsupportedSolarDate` thay vì tạo cell không có dữ liệu âm lịch.
- Reference checks đạt; toàn scheme đạt 58/58 tests.

### M4.2 — Vietnamese formatters

- Thêm formatter deterministic cho compact menu title, ngày dương đầy đủ, ngày âm thường/nhuận, Can–Chi, secondary grid label và cell accessibility label.
- Weekday tiếng Việt được suy từ JDN, không phụ thuộc locale/time-zone của máy chạy.
- Compact leap month dùng hậu tố `N`; mô tả đầy đủ dùng `nhuận`; chuỗi `Tỵ`, `ÂL`, `Bính Ngọ` được test chính xác dấu.
- VoiceOver label khớp product copy trong spec, gồm trạng thái `hôm nay` khi phù hợp.
- Reference checks đạt; toàn scheme đạt 64/64 tests.

### M5.1 — Menu title từ live snapshot

- Thay title `ÂL` placeholder bằng presentation dẫn xuất trực tiếp từ `CalendarSnapshot`; mặc định là `dd/MM ÂL`.
- Thêm năm format ổn định, gồm icon-only; `AppState.titleFormat` là published state nên thay đổi format làm SwiftUI cập nhật ngay, không lưu chuỗi dẫn xuất.
- Accessibility label luôn là tiếng Việt đầy đủ cho ngày dương, ngày âm, Can–Chi ngày/giờ, kể cả khi menu bar chỉ hiện icon.
- App chỉ refresh rõ ràng khi khởi tạo/mở popover; task này không thêm repeating timer.
- Debug app bundle khởi chạy thật thành công; reference checks và toàn scheme đạt 67/67 tests.

### M5.2 — Calendar popover và month navigation

- Thay popover placeholder bằng header live, lưới 6×7, chi tiết ngày chọn và footer Hôm nay/Cài đặt/Thoát.
- UI dùng semantic colors/material nên hỗ trợ light/dark mode; mỗi cell là value view, không tạo observable object riêng.
- Điều hướng tháng giữ ngày chọn khi có thể, clamp ngày cuối tháng, và tự vô hiệu hóa nút khi grid kế tiếp chạm ngoài dải dữ liệu.
- Thêm phép cộng tháng có kiểm tra biên cho `YearMonth`; domain grid/leap/range tests tiếp tục bảo vệ state UI.
- Debug app bundle khởi chạy thật thành công; reference checks và toàn scheme đạt 68/68 tests.

### M5.3 — Keyboard và accessibility

- Thêm `⌘←`/`⌘→` để đổi tháng, phím mũi tên để di chuyển ngày ±1/±7, và Escape để đóng popover.
- Mọi cell có nhãn VoiceOver đầy đủ ngày dương/ngày âm, semantic value `Đã chọn`/`Hôm nay`, selected trait và tooltip; các control điều hướng/footer đều có label/tooltip.
- Build và toàn scheme đạt 68/68 tests; không phát sinh warning dưới warnings-as-errors.
- Manual Accessibility Inspector chưa hoàn tất: macOS từ chối Assistive Access cho tiến trình kiểm tra với lỗi `-1719`. Task chỉ chuyển `Hoàn thành` sau khi chạy Inspector hoặc có AX inspection tương đương được chấp nhận.

### A2 — Deterministic target-dependency UUIDs

- Phát hiện `xcodeproj` tạo UUID thay đổi cho nhiều `PBXTargetDependency` cùng trỏ tới một target, làm `project.pbxproj` churn dù source list không đổi.
- Generator nay cấp chuỗi UUID đầu vào deterministic trước bước path-based predictabilization; không thay đổi target graph hoặc build settings.
- Ba process generate liên tiếp cho checksum byte-identical của cả `project.pbxproj` và shared scheme.
- Toàn scheme tiếp tục đạt 68/68 tests.

### M5.4 — UI smoke tests và đóng accessibility gate

- XCUITest mở trực tiếp `StatusItem` thật, chờ popover, xác nhận today header và visible month title.
- Flow sang tháng sau rồi bấm Hôm nay quay đúng tháng ban đầu; sau đó mở Settings và xác nhận settings scene xuất hiện.
- AX hierarchy xác nhận cell hôm nay có full Vietnamese lunar label, value `Đã chọn, hôm nay` và selected trait; bằng chứng này thay thế manual Inspector bị chặn ở M5.3.
- Sửa root accessibility identifier từng ghi đè identifier của con trên macOS; identifier nay đặt ở element cụ thể.
- Reference checks đạt; toàn scheme đạt 69/69 tests, gồm hai UI tests chạy trên app thật.

### M6.1 — Pure next-boundary calculation

- Thêm `RefreshGranularity`, `RefreshRequirements`, `BoundaryCalculating` và pure `BoundaryCalculator` trong Core.
- Can–Chi hour refresh xét cả 12 odd-hour branch boundaries và civil midnight để cập nhật day stem theo policy mặc định.
- `after` có ngữ nghĩa strictly-after: đúng tại 00:00/01:00/phút tròn luôn tiến tới boundary kế tiếp, không trả lại instant hiện tại.
- Test UTC+7 midnight, mọi boundary quan trọng, minute display time zone, DST spring-forward và nhiều requirements chọn thời điểm sớm nhất.
- Project regeneration vẫn byte-identical; reference checks và toàn scheme đạt 76/76 tests.

### M6.2 — One-shot scheduler

- Thêm `BoundaryScheduling` trên `@MainActor` và `OneShotBoundaryScheduler` dùng đúng một Swift concurrency task, không có repeating timer/publisher.
- Schedule mới cancel task cũ trước khi tạo task thay thế; `cancel()` và `deinit` đều hủy pending sleep; callback chỉ chạy trên MainActor.
- `BoundarySleeping` cho phép production dùng continuous clock với tolerance, còn test dùng manual sleeper không chờ thời gian thật.
- Test exact delay/tolerance, replacement chỉ fire action mới, explicit cancellation, past boundary clamp về 0 và deinit cancellation.
- Reference checks đạt; toàn scheme đạt 80/80 tests.

### M6.3 — Lifecycle source và coalesced refresh

- `SystemLifecycleSource` ánh xạ day changed, clock changed, time-zone changed, app active và wake từ sleep sang typed `AppLifecycleEvent`.
- Popover open và scheduled boundary đi qua cùng event stream, giúp mọi refresh có một đường điều phối thống nhất.
- `LifecycleEventCoordinator` chỉ có một consumer, gom burst cùng lượt MainActor thành một refresh và dừng/cancel sạch.
- `AppState` refresh snapshot rồi thay one-shot UTC+7 midnight; popover không gọi refresh trực tiếp và không tạo timer trùng.
- Test với NotificationCenter/source giả xác nhận mapping, explicit events, burst coalescing, idempotent start và stop; toàn scheme đạt 83/83 tests.

### M6.4 — Idle behavior verification

- Đã chạy hai cửa sổ 5 phút và một diagnostic window; kết quả đầy đủ nằm trong `docs/performance-baseline.md`.
- App phần lớn ngủ và không có repeating log/timer, nhưng low-impact run tăng 12,64 giây CPU time/300 giây và RSS đạt 124.752 KB, vượt gate spec.
- Diagnostic run 91 giây sạch khi đó chưa đủ để phủ nhận failure 5 phút, nên task đã được giữ blocker cho đến khi có Release profile.
- Follow-up A4 chạy Developer ID signed Release trong Time Profiler 300,84 giây: CPU +0,01 giây, 17 running samples hệ thống, không có app-owned loop; M6.4 được đóng bằng evidence mới này.
- RSS cold tại khoảng 30 giây vẫn có lần đạt 63.264 KB; memory review không bị bỏ qua mà chuyển sang M8.2.

### A3 — Stable lifecycle burst coalescing

- `Task.yield()` cho phép refresh task xen giữa các event đã buffer, làm burst ba notification đôi khi tạo hai refresh.
- Thay bằng debounce task one-shot 10 ms; event mới trong cửa sổ này dùng chung pending refresh, không tạo polling/repeating timer.
- Test coordinator dùng cửa sổ 30 ms xác định và đạt ba lần chạy riêng liên tiếp.

### M7.1 — Typed preferences store

- Thêm `AppPreferences` đúng typed schema của spec và tập trung toàn bộ giá trị mặc định ở `defaultValue`.
- `UserDefaultsPreferencesStore` chỉ ghi một root key có schema version; không lưu title dẫn xuất, login-item truth, bảng âm lịch hoặc events.
- Hỗ trợ migration payload v0 sang v1; dữ liệu hỏng, version tương lai hoặc legacy không hợp lệ trả về defaults nhưng không bị xóa.
- Change stream phát giá trị hiện tại và các lần save khác biệt; bộ test dùng isolated `UserDefaults` suite.
- Project generator chạy hai lần byte-identical; reference checks và toàn scheme đạt 88/88 tests.

### M7.2 — Settings UI và live preference integration

- Thay Settings placeholder bằng màn Chung/Giới thiệu: title format, ngày dương, Can–Chi, clock, 24 giờ, đầu tuần, Launch at Login placeholder và thông tin range/privacy/attribution.
- `AppState` load và quan sát typed store; thay đổi preference được lưu rồi áp dụng ngay cho title, snapshot, month grid và boundary policy mà không cần relaunch.
- Bật clock ghép giờ hệ thống từ cùng captured instant vào title/accessibility text và đổi one-shot requirements sang boundary mỗi phút; tắt clock quay về UTC+7 midnight.
- Week-start thay đổi cả thứ tự header lẫn 42-cell grid; title flags ánh xạ xác định vào bốn enum format, không tạo thêm key rời rạc.
- UI test dùng isolated preference suite, mở Settings thật và xác nhận clock preview bật/tắt tức thời; project generation byte-identical, reference checks và toàn scheme đạt 92/92 tests.
- Launch at Login có control bị vô hiệu hóa rõ ràng cho đến khi adapter `SMAppService` được triển khai ở M7.3.

### M7.3 — `SMLoginItemService` implementation và manual gate

- Thêm typed `LoginItemStatus`/`LoginItemServicing` và adapter `SMAppService.mainApp`; register/unregister idempotent cho trạng thái đã đạt.
- Ánh xạ đủ bốn trạng thái SDK: `notRegistered`, `enabled`, `requiresApproval`, `notFound`; unknown status fail-safe về `unavailable`.
- Settings lấy trạng thái trực tiếp từ macOS khi xuất hiện và sau lifecycle activation, không lưu login-item truth vào preferences.
- Trạng thái cần phê duyệt có hướng dẫn và action mở Login Items trong System Settings; lỗi register/unregister hiển thị không fatal.
- Mapping test và toàn scheme đạt 93/93; Release universal app build đạt và Developer ID signature được verify local.
- Chưa cài bundle vào `/Applications` hoặc gọi register thật vì hai thao tác này thay đổi trạng thái hệ thống; task giữ `Bị chặn` cho đến khi manual gate đó được người dùng cho phép và xác nhận.

### M7.4 — Dock/accessory behavior và calendar detail

- Header popover dùng đầy đủ ngày dương/weekday và ngày âm/năm Can–Chi; thêm ghi chú canonical `Lịch Việt Nam: UTC+7` ngay trong giao diện.
- Selected-day detail trình bày năm/tháng/ngày Can–Chi thành các semantic elements riêng; Can–Chi giờ chỉ tồn tại khi ngày chọn là hôm nay.
- UI flow xác nhận app launch background, status item còn tồn tại sau khi mở Settings, Settings activatable và nút Quit luôn có trong popover.
- Clean Release bundle được ký cùng Developer ID cho app và hai framework, verify chữ ký rồi launch thật; `NSRunningApplication.activationPolicy` trả `accessory`, không tạo Dock app kiểu regular.
- Process kiểm tra đã được terminate sau khi đo; không cài vào `/Applications` và không thay đổi login-item state.
- Reference checks, Debug build và toàn scheme đạt 93/93 tests; Release build đạt.

### M8.1 — Full test matrix partial completion

- Thêm exhaustive self-consistency cho toàn bộ 146.097 ngày theo cả hai chiều solar → lunar → solar và lunar → solar → lunar.
- Tách rõ round-trip với independent conformance: test mới có thể bắt lỗi ánh xạ/bijection nhưng không dùng production-derived JSON làm oracle.
- `docs/release-test-matrix.md` ghi môi trường, các gate tự động đã đạt và điều kiện đóng từng checklist còn thiếu.
- Unit/property/lifecycle/preferences/UI, clean Release build, static offline boundary và accessory runtime đều đã có bằng chứng.
- Full Debug scheme đạt 95/95 tests; Release executable là universal `x86_64 arm64`, `LSUIElement=true` và không có outbound network entitlement.
- Task giữ `Bị chặn` vì independent oracle/2033, installed login item, real sleep/wake và offline runtime vẫn là gates bắt buộc.

### A4 — Signed Release idle verification

- Clean Release bundle được ký cùng Developer ID cho app và hai embedded frameworks trước khi launch, tránh Team ID mismatch của ad-hoc hardened runtime.
- Time Profiler chạy đủ 300,84 giây với popover đóng/default preferences; CPU time tăng 0,01 giây, thấp hơn nhiều target 0,1%.
- 17 running samples đều nằm trong system callbacks/run loop; không có repeating timer, polling hoặc VietLunar-owned hot stack.
- RSS giảm 50.816 KB → 31.232 KB trong profiler window; transient cold RSS >60 MB vẫn là blocker riêng của M8.2.
- Power Profiler không hỗ trợ macOS host; Allocations CLI attach lỗi và gây nhiễu nên không được dùng làm bằng chứng đạt.
