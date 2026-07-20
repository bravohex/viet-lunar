# VietLunar release test matrix

**Ngày chạy:** 2026-07-20

**Máy:** Mac mini, Apple Silicon

**Hệ điều hành:** macOS 26.5.2
**Toolchain:** Xcode 26.0.1, Swift 6 strict concurrency

## Kết quả tự động

| Hạng mục | Kết quả | Bằng chứng |
|---|---|---|
| Reference artifact integrity | Đạt | Catalog, candidate JSON và generated Swift checksum hợp lệ |
| Full automated scheme | Đạt | 98/98 unit, property, UI và signpost metric tests; warnings-as-errors |
| Solar → lunar → solar | Đạt | Toàn bộ 146.097 ngày dương trong 1800-2199 |
| Lunar → solar → lunar | Đạt | Toàn bộ 146.097 ngày âm ánh xạ vào production range |
| Can–Chi/JDN/boundary | Đạt | Full-range day cycle, 1.440 phút, UTC+7, minute và DST tests |
| Lifecycle/scheduler | Đạt | Synthetic day/clock/time-zone/wake/active events; one-shot/coalescing tests |
| Preferences/login mapping | Đạt | Migration/change stream và bốn `SMAppService.Status` mappings |
| UI smoke | Đạt | Launch background, popover, month nav, Today, Settings, relaunch persistence, live clock, Quit |
| Release build | Đạt | Clean universal Release; AppIcon + 7 template assets, một embedded Core framework, static Infrastructure và deep signature verify |
| Accessory behavior | Đạt | Signed Release launch thật; activation policy là `accessory` |
| Network dependency static check | Đạt | Không có network API/runtime package hoặc outbound network entitlement |
| Runtime network observation | Đạt | Signed Release, 60 mẫu nettop và lsof trước/sau không có socket/traffic |
| Vietnamese localization resources | Đạt | 96 App/Core keys; catalog coverage và compiled app/framework resources được kiểm tra |
| Popover performance | Đạt measurement gate | Release signposts: first median 131,38 ms (<200 hard); subsequent 44,16 ms (<50 target) |

## Gate chưa đạt

| Hạng mục bắt buộc | Trạng thái | Điều kiện đóng |
|---|---|---|
| Independent exhaustive oracle | Bị chặn | MIT candidate đã audit nhưng lệch 13.028 ngày; Ho table bị giới hạn non-commercial; cần nguồn 1800-2199 khác được duyệt |
| Independent 2033 evidence | Bị chặn | MIT candidate khớp và ghi leap month 11; vẫn cần validation thứ hai được chấp thuận và đóng dependency M2.5 |
| Signed installed login item | Chờ quyền thay đổi hệ thống | Cài vào `/Applications`, test enable/disable/approval rồi dọn trạng thái |
| Real sleep/wake and clock change | Chờ kiểm tra thủ công | Chạy checklist trên signed installed app |
| Offline runtime | Chờ kiểm tra thủ công | Chạy app khi network adapter thực sự tắt; runtime zero-traffic đã xác nhận riêng |
| Launch/RSS performance | Bị chặn | Static Infrastructure đưa RSS median dưới target 35 MB; đúng current binary có launch-to-ready median 857,32 ms >800 ms, app work median 22,05 ms |

## Kết luận

Matrix tự động và exhaustive round-trip đã đạt, nhưng đây chưa phải release approval. Candidate lunar table và production engine có chung nguồn sinh nên round-trip không thay thế independent conformance. M8.1 giữ trạng thái bị chặn cho đến khi toàn bộ gate thủ công và accuracy ở trên được đóng.
