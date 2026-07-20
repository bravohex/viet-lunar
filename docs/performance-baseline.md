# VietLunar performance baseline

Ngày đo: 2026-07-20

Máy: Mac mini arm64, macOS 26.5.2

Builds: Debug và Developer ID signed Release, popover đóng, title mặc định, không bật clock

## M6.4 — Idle behavior

### Kết quả

| Run | Cửa sổ | CPU time | RSS | Log ứng dụng | Kết luận |
|---|---:|---:|---:|---:|---|
| A — sampled | 321 giây | +2,44 giây | 15 MB → 60 MB sau khi attach sampler | 0 | 28/31 mẫu là 0,0%; có hai spike rời rạc; sampler gây nhiễu |
| B — low impact | 300 giây | +12,64 giây | 73.728 KB → 124.752 KB | 0 | Fail ngưỡng idle CPU/RSS; không attach trong cửa sổ chính |
| C — diagnostic rebuild | 91 giây | +0,01 giây | 75.696 KB → 63.200 KB | 0 | Sạch nhưng chưa đủ dài để thay thế run B |
| D — signed Release Time Profiler | 300,84 giây | +0,01 giây | 50.816 KB → 31.232 KB | 0 | Đạt idle CPU; 17 running samples, không có app-owned loop |

Run A lấy mẫu `top` mỗi 10 giây. Ở cuối run, `sample` thấy main thread nằm trong `mach_msg` ở 929/1.010 stack samples, phù hợp với trạng thái chờ phần lớn thời gian. Tuy nhiên hai spike làm kết quả trung bình không đạt.

Run B chỉ đọc `ps` ở đầu và cuối sau 20 giây warm-up, có heartbeat shell không attach vào process. CPU time tăng từ 0,19 lên 12,83 giây trong đúng 5 phút, tương đương khoảng 4,21% của một CPU core. RSS cuối kỳ vượt mục tiêu 60 MB trong spec.

Run C được dùng để kiểm tra nhanh sau rebuild và cho thấy không có busy loop liên tục, nhưng không giải thích được spike dài ở run B.

Run D dùng clean universal Release bundle, ký Developer ID nhất quán cho app và hai framework, rồi attach Xcode Time Profiler trong đúng 300,84 giây. CPU time tăng từ 0,20 lên 0,21 giây, tương đương khoảng 0,0033% một CPU core. Trace chỉ có 17 running samples × 1 ms; call stacks là AppKit run loop, LaunchServices, XPC, allocator và system notification callbacks. Không có stack lặp của VietLunar hoặc scheduler.

RSS trong run D giảm từ 50.816 KB xuống 31.232 KB. Một phép đo cold Release riêng ghi nhận 63.264 KB tại khoảng 30 giây rồi tiếp tục giảm; đây vẫn vượt hard-review threshold 60 MB tại mốc 30 giây và được giữ làm blocker của M8.2. Allocations attach thử nghiệm thất bại và tự làm RSS/CPU tăng nên không được dùng làm baseline.

### Các điều kiện đã xác nhận

- Không có `Timer.publish(every:)` hoặc repeating timer trong code path hiện tại.
- Scheduler production chỉ giữ một Swift concurrency sleep đến boundary UTC+7 kế tiếp; replacement/cancel/deinit đã có test.
- Unified log của process không có dòng lặp theo giây/phút trong cả hai run 5 phút.
- Popover được đóng trong toàn bộ thời gian đo.
- Signed Release Time Profiler xác nhận không có sustained app-owned CPU work trong 5 phút.

### Gate và bước tiếp theo

M6.4 đạt theo signed Release evidence: không repeating timer/log và idle CPU thấp hơn target 0,1%. Debug run B được giữ lại để tránh che giấu lịch sử failure, nhưng Release trace giải thích rằng đó không phải sustained application loop.

Memory gate chuyển sang M8.2: cần Allocations/VM investigation ổn định cho transient RSS ở mốc 30 giây. Xcode Power Profiler không hỗ trợ host macOS trong toolchain này; Allocations CLI attach đã báo lỗi nên chưa đủ bằng chứng để đóng memory review.

## M8.2 — Release/component baseline

### Kết quả

| Metric | Kết quả đo | Target / hard review | Kết luận |
|---|---:|---:|---|
| Cold launch đến initial frame | 951,10 ms | <=400 / <=800 ms | Fail hard review |
| AppKit init đến initial frame | 330,43 ms | Thông tin phân rã | Phần app-side thấp hơn full launch |
| Popover first/subsequent open | Chưa có phép đo không nhiễu | <=100/50 ms | Blocker |
| RSS khoảng 30 giây | 63.264 KB | <=35 MB / review >60 MB | Fail hard review |
| RSS cuối idle trace | 31.232 KB | <=35 MB | Đạt sau warm-up |
| Idle CPU 5 phút | +0,01 s / 300,84 s | <=0,1% | Đạt |
| Release app bundle | 2.284 KB (2,2 MB) | <=10 / <=20 MB | Đạt |
| Cold first conversion | 0,023417-0,102542 ms | Thông tin warm-up | Ghi range |
| Conversion p95 | 0,000084 ms | <=0,05 / <=0,5 ms | Đạt |
| 146.097 conversions | 11,999958 ms | Không có hard gate tổng | Median 3 runs |
| 146.097 round trips | 11,595458 ms | Không có hard gate tổng | Median 3 runs |
| 1.000 month grids p95 | 0,003041 ms/grid | <=2 / <=10 ms | Đạt |
| 10.000 menu formats | 25,032667 ms | Không có hard gate | Median 3 runs |

Core benchmark được compile optimized whole-module với Swift 6 strict concurrency. Bảng ghi median của ba lần chạy liên tiếp sau khi hoàn thiện script, riêng cold conversion ghi min-max. Checksum `297986322` buộc kết quả được tiêu thụ, tránh compiler loại bỏ workload.

App Launch trace 5,52 giây ghi process creation 512,13 ms, sau đó AppKit initialization bắt đầu tại 620,68 ms và initial frame kết thúc tại 951,10 ms. Instruments có overhead, nhưng full result vẫn vượt hard-review threshold nên không được báo đạt.

XCUITest xác minh popover mở đúng nhưng event synthesis/polling khoảng một giây làm số thời gian không dùng được như product performance metric. Cần signpost hoặc Instruments interaction trace để đo first/subsequent open không nhiễu.

### M8.2 gate

M8.2 chưa đạt vì cold launch và transient RSS vượt hard-review threshold, popover timing chưa được đo tin cậy, và Allocations CLI attach thất bại. Core/grid/bundle/idle CPU đều đạt, nên không có bằng chứng cần viết lại calendar core; điều tra tiếp tập trung vào SwiftUI/MenuBarExtra launch và resident memory.
