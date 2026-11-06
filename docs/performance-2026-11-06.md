# Kiểm tra hiệu năng VietLunar — 2026-11-06

Đo trên Apple M4, RAM 16 GiB, macOS 26.6.2, Xcode 26.0.1. Code ứng dụng tương ứng commit `8262aca` (quản lý/xóa ICS); version vẫn là 0.2.1 build 10. Đây là bản build local, không phải artifact v0.2.1 đã phát hành.

## Phạm vi và cách chạy

- `./scripts/benchmark.sh`: Swift 6, `-O -whole-module-optimization`; chạy ba lần. Parse 100 lần, dựng index 1.000 lần, tra 42 ngày × 1.000 lần. File đi kèm 454.849 byte, 2.167 sự kiện, năm 2000–2050. Checksum cả ba lần: `298214022`.
- `./scripts/measure_popover.sh`: Release arm64, ad-hoc signing, testability bật; compile flag `PERFORMANCE_TESTING` chỉ cho phép bộ đo dùng preferences/kho ICS riêng. Bản phát hành thông thường không có hook này. Ba mẫu được XCTest giữ lại sau warm-up; mỗi mẫu khởi chạy process mới, mở/đóng/mở lại popover.
- Nguồn mặc định, không có ICS người dùng, đồng hồ tắt. Không đọc/xóa các bản sao ICS thật của người dùng.
- Signpost đo công việc phía app trong launch callback và thao tác mở popover đến `displayIfNeeded`; không gồm thời gian tạo process trước callback, tổng cold launch, overhead click/polling XCTest hoặc thời điểm pixel cuối cùng lên màn hình. Ba mẫu không đủ để tính p95 đáng tin cậy của UI.

## Popover và khởi tạo app

Đơn vị ms.

| Metric | Ba mẫu | Median |
|---|---|---:|
| Duration (Application App Work) | 22.096, 17.582, 41.201 | 22.096 |
| Duration (Popover Subsequent Open) | 50.162, 40.151, 43.163 | 43.163 |
| Duration (Popover First Open) | 131.007, 127.893, 265.223 | 131.007 |

Mở lại đạt mục tiêu median 50 ms trong spec; một mẫu 50,162 ms sát/vượt nhẹ mục tiêu. Mở lần đầu median 131 ms vượt mục tiêu 100 ms; mẫu 265 ms vượt ngưỡng review 200 ms. **Chưa đóng gate first-open latency**. Không loại bỏ mẫu chậm, và không suy ra nguyên nhân của spike từ ba mẫu này. Cần trace Time Profiler/SwiftUI trong phiên ít nhiễu để phân biệt dựng view, layout, asset, tải ICS và tác động hệ thống.

## Core và dữ liệu ngày lễ

Mỗi ô là p95 của một lần chạy, đơn vị ms; cột cuối lấy median của ba p95.

| Metric | Run 1 | Run 2 | Run 3 | Median p95 |
|---|---:|---:|---:|---:|
| Đổi dương → âm | 0.000125 | 0.000084 | 0.000042 | 0.000084 |
| Dựng lưới tháng | 0.002125 | 0.003083 | 0.003458 | 0.003083 |
| Parse ICS mặc định | 27.237458 | 25.540583 | 25.132208 | 25.540583 |
| Dựng holiday index | 0.285583 | 0.276084 | 0.264625 | 0.276084 |
| Tra ngày lễ cho 42 ngày | 0.000417 | 0.000417 | 0.000458 | 0.000417 |

Parser benchmark bắt đầu sau khi file đã đọc vào RAM; không gồm disk I/O. Index/lookup là microbenchmark trong bộ nhớ, không phải thời gian render màn hình. App giữ index và không parse lại ICS trên mỗi lần chuyển tháng. Với workload mặc định, tính lịch/lookup không phải ứng viên ưu tiên tối ưu.

10.000 lần format menu mất 495,817 / 476,453 / 475,057 ms, tương đương khoảng 0,048 ms/lần ở median. Số này không đủ để kết luận regression so với baseline tháng 7 vì source, hệ điều hành và workload đã thay đổi.

## RSS và CPU khi idle

Một process mới chạy trực tiếp từ `.build/PopoverMetricDerivedData/Build/Products/Release/VietLunar.app/Contents/MacOS/VietLunar`, với `VIETLUNAR_TEST_PREFERENCES_SUITE=VietLunarUITests.Idle.<UUID>`. Không mở popover/Cài đặt, không bật đồng hồ, không attach Instruments. Đọc `ps -p <PID> -o rss=,time=` tại 5/30/60/90 giây rồi kết thúc đúng PID do phép đo tạo ra.

| Mốc thực tế (s) | RSS (KiB) | RSS (MiB) | CPU tích lũy (s) |
|---:|---:|---:|---:|
| 5.016 | 36176 | 35.33 | 0.06 |
| 30.015 | 31408 | 30.67 | 0.06 |
| 60.014 | 33696 | 32.91 | 0.06 |
| 90.014 | 31584 | 30.84 | 0.06 |

Từ mốc 30 đến 90 giây, CPU không tăng ở độ phân giải 0,01 s của `ps`; không đồng nghĩa CPU tuyệt đối bằng 0. RSS ở các mốc này khoảng 30,7–32,9 MiB, dưới target 35 MB và ngưỡng review 60 MB của spec trong phiên đo này. RSS bao gồm trang resident/chia sẻ và không phải physical footprint. Đây là phiên idle ngắn **chưa từng mở popover**, lúc dữ liệu ngày lễ còn lazy-load; không suy rộng thành mức RAM sau khi tương tác hoặc kiểm tra leak. Không thay thế bài đo energy/idle dài hạn năm phút.

Bundle Release arm64 dùng cho test chiếm 4.480 KiB theo `du -sk` (~4,38 MiB). Đây không phải kích thước archive universal/notarized để phát hành.

## Kiểm chứng chức năng

`./scripts/test.sh --skip-performance`: 195 XCTest pass, 0 fail, cùng 14 Python script tests và localization validation. UI test kiểm tra nguồn nhập được seed vào kho riêng, thao tác hủy/xóa khi nguồn mặc định đang chọn và trạng thái sau relaunch; không chứng minh luồng native file picker. Store test đọc tệp gốc, nhập bản sao, xóa và kiểm tra byte của tệp gốc không đổi; AppState tests bao gồm nguồn đang dùng, không dùng, tắt ngày lễ và lỗi lưu trữ. `./scripts/measure_popover.sh` pass riêng với ba nhóm signpost ở trên. Đây là xác minh local, chưa phải remote CI.

## Điểm cần theo dõi

`FileHolidaySourceStore.loadSources()` hiện đọc/parse mọi nguồn đồng bộ; AppState gọi lần đầu khi mở lịch/Cài đặt và gọi lại sau nhập/xóa. Vì vậy thêm nhiều ICS lớn có thể làm lần mở đầu hoặc thao tác quản lý chậm, dù chỉ chọn một nguồn. Chưa đo workload nhiều ICS/giới hạn parser trong đợt này. Nếu đó là cách dùng thực tế, ưu tiên benchmark cold load/import/delete theo số nguồn rồi cân nhắc cache theo file hoặc nạp nền; không thay cơ chế dữ liệu chỉ dựa trên microbenchmark.

Kết quả này không xác nhận pin/energy, memory leak dài hạn, cold launch từ lúc tạo process, Intel hoặc các bản macOS khác. Baseline cũ trong `performance-baseline.md` là dữ liệu lịch sử, không tự động kế thừa trạng thái pass sang bản hiện tại.
