# VietLunar acceptance review

**Ngày rà soát:** 2026-07-20

**Phạm vi:** `VietLunar_SPEC.md` mục 19

**Kết luận phát hành:** **KHÔNG PHÁT HÀNH**

Kết quả hiện tại: **26/32 tiêu chí đạt**, **6/32 tiêu chí bị chặn**. Không có ADR hoặc waiver nào được chấp thuận để bỏ qua tiêu chí chưa đạt.

Quy ước trạng thái:

- `Đạt`: có test, kiểm tra tĩnh, build hoặc bằng chứng chạy thật phù hợp với tiêu chí.
- `Bị chặn`: thiếu bằng chứng bắt buộc, đang fail hard threshold hoặc cần quyền/thao tác hệ thống chưa được cho phép.

## 19.1 — Nghiệm thu chức năng MVP

| ID | Tiêu chí | Trạng thái | Bằng chứng / việc còn lại |
|---|---|---|---|
| F1 | App xuất hiện trên menu bar sau launch | Đạt | Signed Release và `testApplicationLaunches` xác nhận app chạy background với status item. |
| F2 | Dock icon ẩn mặc định | Đạt | `LSUIElement=YES`, activation policy `accessory`, signed Release launch đã kiểm tra. |
| F3 | Tiêu đề mặc định hiện ngày/tháng âm hiện tại | Đạt | `AppState.menuBarPresentation`, formatter tests và UI smoke dùng live snapshot UTC+7. |
| F4 | Click tiêu đề mở calendar popover | Đạt | UI smoke mở status item và tìm thấy `today-header`. |
| F5 | Hiện ngày dương và âm của hôm nay | Đạt | UI smoke xác nhận today header/cell và accessibility label chứa ngày âm. |
| F6 | Tháng nhuận không mơ hồ | Đạt | Formatter ghi rõ `nhuận`; engine và formatter có test tháng nhuận. |
| F7 | Hiện Can–Chi năm/tháng/ngày/giờ đúng quy ước | Đạt | Full Can–Chi tests; UI smoke xác nhận bốn phần và ghi chú UTC+7. |
| F8 | Tháng trước/sau và Hôm nay hoạt động | Đạt | UI smoke điều hướng sang tháng kế tiếp rồi quay lại hôm nay. |
| F9 | Biên dải hỗ trợ không crash | Đạt | Engine/grid boundary tests trả typed error và disable hướng điều hướng không hợp lệ. |
| F10 | Settings giữ nguyên sau relaunch | Đạt | `testSettingsPersistAfterRelaunch` bật đồng hồ, dừng, launch lại và xác nhận giá trị còn hiệu lực. |
| F11 | Launch-at-login bật/tắt được và status chính xác | Bị chặn | Mapping/code đạt; chưa cài signed app vào `/Applications` để register/unregister/approval thật. |
| F12 | App hoạt động khi networking bị tắt | Bị chặn | Static check đạt; chưa có offline run hoặc network capture trên signed installed app. |
| F13 | Có lệnh Quit | Đạt | UI smoke xác nhận `quit-button`; action gọi terminate ứng dụng. |

## 19.2 — Nghiệm thu độ chính xác

| ID | Tiêu chí | Trạng thái | Bằng chứng / việc còn lại |
|---|---|---|---|
| A1 | Exhaustive comparison với reference độc lập đạt | Bị chặn | Candidate JSON và production table dùng chung generator; cần oracle 1800–2199 độc lập có license/provenance. |
| A2 | Exhaustive round trip đạt | Đạt | 146.097 solar→lunar→solar và 146.097 lunar→solar→lunar đều đạt. |
| A3 | Regression năm 2033 đạt | Bị chặn | Chuỗi expected hiện pass, nhưng chưa có hai nguồn độc lập được lưu; một nguồn phải xác nhận tháng 11 nhuận Việt Nam. |
| A4 | Can–Chi formula và chu kỳ 60 ngày đạt | Đạt | Golden 2004, JDN, exhaustive day cycle và +60 ngày đạt. |
| A5 | UTC+7 day-boundary tests đạt | Đạt | Trước/sau nửa đêm, year boundary và snapshot consistency đạt. |
| A6 | Sleep/wake và đổi system clock refresh đúng | Bị chặn | Fake lifecycle tests đạt; checklist trên signed installed app với sự kiện hệ thống thật chưa chạy. |
| A7 | Ngoài dải trả typed error, không xấp xỉ | Đạt | Engine/date/grid boundary tests xác nhận typed errors. |

## 19.3 — Nghiệm thu hiệu năng

| ID | Tiêu chí | Trạng thái | Bằng chứng / việc còn lại |
|---|---|---|---|
| P1 | Không repeating timer ở cấu hình mặc định | Đạt | One-shot scheduler, source scan và replacement/cancel tests; không có polling theo giây. |
| P2 | Không sustained idle CPU work | Đạt | Signed Release Time Profiler 300,84 giây chỉ tăng 0,01 giây CPU, không có app-owned loop. |
| P3 | Không có network traffic bất ngờ | Đạt | Signed Release: 60 mẫu `nettop` không có process/socket row hoặc bytes; `lsof` trước/sau không có Internet socket. |
| P4 | Có số đo launch, popover, memory và conversion | Đạt | Release signposts sau static relink: first median 112,78 ms, subsequent median 35,41 ms; launch/RSS/conversion có trace/benchmark riêng. |
| P5 | Vi phạm hard threshold có profiling note và quyết định được duyệt | Bị chặn | AppKit shell + static Infrastructure đưa RSS median xuống 32.496 KB, nhưng App Launch median 846,92 ms vẫn vượt 800 ms; chưa có fix đạt ngưỡng hoặc waiver được chấp thuận. |

## 19.4 — Nghiệm thu chất lượng code

| ID | Tiêu chí | Trạng thái | Bằng chứng / việc còn lại |
|---|---|---|---|
| Q1 | Core không import SwiftUI/AppKit | Đạt | Toàn bộ `Sources/Core` chỉ phụ thuộc Foundation/Core API. |
| Q2 | Không có runtime third-party package | Đạt | Xcode project không có package reference; app nhúng Core framework nội bộ và link tĩnh Infrastructure. |
| Q3 | Không force unwrap trong date conversion paths | Đạt | Source scan và warnings-as-errors không phát hiện force unwrap trong Core conversion. |
| Q4 | Generated data có provenance/checksum | Đạt | Source catalog, metadata và checksum verification script đều đạt; independent accuracy vẫn thuộc gate A1/A3. |
| Q5 | Mọi user-visible string nằm trong localized resources | Đạt | App/Core có Vietnamese string catalogs; 96 khóa được đối chiếu tự động, resources được kiểm tra trong built app/framework. |
| Q6 | Strict concurrency warnings đã giải quyết | Đạt | Swift 6 complete strict concurrency và warnings-as-errors; clean Release/full tests build đạt. |
| Q7 | README ghi build, test, distribution và calendar conventions | Đạt | README liên kết privacy, notice, WBS và distribution guide; UTC+7/range/historical caveat đã ghi. |

## Release blockers cần đóng

1. Cung cấp independent oracle có quyền sử dụng và hai bằng chứng độc lập cho chuỗi 2033.
2. Xử lý launch hard threshold hoặc có ADR/waiver được người có thẩm quyền phê duyệt.
3. Với quyền thay đổi hệ thống, cài signed app và chạy login-item, sleep/wake, clock-change, offline/network checklist.

M8.4 chỉ được chuyển sang `Hoàn thành` khi tất cả mục `Bị chặn` đã được sửa hoặc có ADR/waiver được người có thẩm quyền chấp thuận.
