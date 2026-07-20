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
| M3.2 | Can-Chi năm/tháng/ngày | M3.1, M1.2 | Chờ | — | Golden vectors + chu kỳ 60 ngày |
| M3.3 | Can-Chi giờ và boundary policy | M3.2 | Chờ | — | Toàn bộ mốc giờ nhánh địa chi |
| M3.4 | `CalendarSnapshotFactory` | M2.4, M3.3, M1.3 | Chờ | — | FixedClock midnight/hour tests |
| M4.1 | `MonthGridBuilder` 42 ô | M2.4 | Chờ | — | Week starts, leap February, boundary tests |
| M4.2 | Vietnamese formatters | M3.4, M4.1 | Chờ | — | Exact string/diacritics/accessibility tests |
| M5.1 | Menu title từ live snapshot | M3.4, M4.2 | Chờ | — | State/preference update tests + build |
| M5.2 | Calendar popover và month navigation | M4.1, M5.1 | Chờ | — | Build + view/domain tests |
| M5.3 | Keyboard và accessibility | M5.2 | Chờ | — | Keyboard semantics tests; Accessibility Inspector thủ công |
| M5.4 | UI smoke tests | M5.3 | Chờ | — | Launch/open/navigate/today/settings UI tests |
| M6.1 | Pure next-boundary calculation | M3.3 | Chờ | — | Midnight/minute/hour/time-zone tests |
| M6.2 | One-shot scheduler | M6.1 | Chờ | — | Cancellation/single-task/fake scheduler tests |
| M6.3 | Lifecycle source và coalesced refresh | M6.2, M5.1 | Chờ | — | Synthetic lifecycle tests |
| M6.4 | Xác minh idle behavior | M6.3 | Chờ | — | `docs/performance-baseline.md` + Instruments thủ công |
| M7.1 | Typed preferences store | M0.3 | Chờ | — | Defaults, isolated suite, migration/change stream tests |
| M7.2 | Settings UI | M7.1, M5.1, M6.3 | Chờ | — | Build + preference integration tests |
| M7.3 | `SMLoginItemService` | M7.2 | Chờ | — | Status mapping tests; signed install thủ công |
| M7.4 | Hoàn thiện Dock/accessory behavior | M7.3 | Chờ | — | Installed-app behavior checklist |
| M8.1 | Chạy full test matrix | M2-M7 | Chờ | — | Unit/exhaustive/UI/Release build/checklists |
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
