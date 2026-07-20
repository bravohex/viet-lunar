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
| Cold launch đến initial frame | 718,08–888,14 ms; median 829,33 ms | <=400 / <=800 ms | Cải thiện nhưng vẫn fail hard review |
| AppKit init đến initial frame | 212,50–249,40 ms; median 224,06 ms | Thông tin phân rã | Cải thiện so với 330,43 ms cũ |
| Popover first/subsequent open | Chưa có phép đo không nhiễu | <=100/50 ms | Blocker |
| RSS khoảng 30 giây | 32.816–42.384 KB; median 37.776 KB | <=35 MB / review >60 MB | Qua hard review; target chưa ổn định |
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

### A8 — Kiểm tra sau khi trì hoãn launch work

`AppState` vẫn tạo live snapshot và lịch one-shot ngay khi launch, nhưng không còn dựng month grid hoặc gọi `SMAppService.status()` trước khi giao diện tương ứng được mở. UI smoke tests tiếp tục xác nhận popover, grid và Settings hoạt động sau khi chuyển thời điểm thực thi.

Clean universal Release bundle được ký nhất quán rồi launch trực tiếp ngoài Xcode, popover đóng và preferences mặc định. Ba lần đọc resident RSS tại khoảng 30 giây:

| Run | RSS | CPU time tích lũy |
|---|---:|---:|
| A8-1 | 70.000 KB | 0,08 giây |
| A8-2 | 67.648 KB | 0,07 giây |
| A8-3 | 66.976 KB | 0,07 giây |

Median RSS là 67.648 KB, vẫn cao hơn hard-review threshold 60 MB. Thay đổi loại bỏ công việc không cần thiết khỏi launch path nhưng không đủ để đóng memory gate; cold launch 951,10 ms cũ cũng chưa được thay bằng trace mới. P5/M8.2 tiếp tục `Bị chặn`.

### A9 — AppKit shell fallback

Theo fallback của spec, application lifecycle và status item được chuyển sang AppKit `NSApplicationDelegate` + `NSStatusItem` + `NSPopover`. SwiftUI chỉ tạo hosting controller cho popover/Settings khi người dùng mở; AppState, core và correctness-critical live snapshot/one-shot boundary vẫn khởi tạo khi launch.

Ba signed Release run với popover chưa từng mở ghi RSS tại khoảng 30 giây là 42.384, 37.776 và 32.816 KB; median 37.776 KB. Cả ba qua hard-review threshold 60 MB, một run qua target 35 MB nhưng median chưa qua target.

Ba App Launch trace trên cùng bundle kết thúc initial frame ở 888,14, 829,33 và 718,08 ms; lần đầu được chạy ngay sau clean build/sign. Median 829,33 ms vẫn cao hơn hard threshold 800 ms. Phần từ AppKit initialization đến initial frame giảm từ 330,43 ms cũ xuống 212,50–249,40 ms, trong khi process creation vẫn biến thiên 366,17–498,18 ms.

Kết quả này đóng vi phạm RSS hard-review nhưng không đóng P5: launch vẫn fail và first/subsequent popover chưa có phép đo không nhiễu. ADR kiến trúc không phải waiver cho các ngưỡng còn fail.

### M8.2 gate

M8.2 chưa đạt vì cold/median launch vẫn vượt hard-review threshold và popover timing chưa được đo tin cậy. RSS 30 giây đã xuống dưới mức hard review nhờ AppKit shell nhưng target 35 MB chưa ổn định; Allocations CLI attach vẫn chưa tạo được trace tin cậy. Core/grid/bundle/idle CPU đều đạt và calendar core không bị viết lại.
