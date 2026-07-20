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
