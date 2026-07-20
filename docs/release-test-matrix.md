# VietLunar release test matrix

**Ngày chạy:** 2026-07-20

**Máy:** Mac mini, Apple Silicon

**Hệ điều hành:** macOS 26.5.2
**Toolchain:** Xcode 26.0.1, Swift 6 strict concurrency

## Kết quả tự động

| Hạng mục | Kết quả | Bằng chứng |
|---|---|---|
| Reference artifact integrity | Đạt | Catalog, candidate JSON và generated Swift checksum hợp lệ |
| Unit/property tests | Đạt | Full Debug scheme 95/95 tests; warnings-as-errors |
| Solar → lunar → solar | Đạt | Toàn bộ 146.097 ngày dương trong 1800-2199 |
| Lunar → solar → lunar | Đạt | Toàn bộ 146.097 ngày âm ánh xạ vào production range |
| Can–Chi/JDN/boundary | Đạt | Full-range day cycle, 1.440 phút, UTC+7, minute và DST tests |
| Lifecycle/scheduler | Đạt | Synthetic day/clock/time-zone/wake/active events; one-shot/coalescing tests |
| Preferences/login mapping | Đạt | Migration/change stream và bốn `SMAppService.Status` mappings |
| UI smoke | Đạt | Launch background, popover, month nav, Today, Settings, live clock, Quit |
| Release build | Đạt | Clean universal Release build; embedded frameworks và signature verify |
| Accessory behavior | Đạt | Signed Release launch thật; activation policy là `accessory` |
| Network dependency static check | Đạt | Không có network API/runtime package hoặc outbound network entitlement |

## Gate chưa đạt

| Hạng mục bắt buộc | Trạng thái | Điều kiện đóng |
|---|---|---|
| Independent exhaustive oracle | Bị chặn | Dataset 1800-2199 độc lập, có license/provenance được duyệt |
| Independent 2033 evidence | Bị chặn | Hai nguồn độc lập, gồm nguồn xác nhận tháng 11 nhuận Việt Nam |
| Signed installed login item | Chờ quyền thay đổi hệ thống | Cài vào `/Applications`, test enable/disable/approval rồi dọn trạng thái |
| Real sleep/wake and clock change | Chờ kiểm tra thủ công | Chạy checklist trên signed installed app |
| Offline runtime | Chờ kiểm tra thủ công | Chạy app khi network tắt hoặc capture traffic xác nhận zero outbound |
| Idle energy/RSS | Bị chặn | Instruments trên signed Release; xử lý failure 5 phút đã ghi nhận |

## Kết luận

Matrix tự động và exhaustive round-trip đã đạt, nhưng đây chưa phải release approval. Candidate lunar table và production engine có chung nguồn sinh nên round-trip không thay thế independent conformance. M8.1 giữ trạng thái bị chặn cho đến khi toàn bộ gate thủ công và accuracy ở trên được đóng.
