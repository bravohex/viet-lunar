# VietLunar performance baseline

Ngày đo: 2026-07-20  
Máy: Mac mini arm64, macOS 26.5.2  
Build: Debug, app đóng popover, title mặc định, không bật clock

## M6.4 — Idle behavior

### Kết quả

| Run | Cửa sổ | CPU time | RSS | Log ứng dụng | Kết luận |
|---|---:|---:|---:|---:|---|
| A — sampled | 321 giây | +2,44 giây | 15 MB → 60 MB sau khi attach sampler | 0 | 28/31 mẫu là 0,0%; có hai spike rời rạc; sampler gây nhiễu |
| B — low impact | 300 giây | +12,64 giây | 73.728 KB → 124.752 KB | 0 | Fail ngưỡng idle CPU/RSS; không attach trong cửa sổ chính |
| C — diagnostic rebuild | 91 giây | +0,01 giây | 75.696 KB → 63.200 KB | 0 | Sạch nhưng chưa đủ dài để thay thế run B |

Run A lấy mẫu `top` mỗi 10 giây. Ở cuối run, `sample` thấy main thread nằm trong `mach_msg` ở 929/1.010 stack samples, phù hợp với trạng thái chờ phần lớn thời gian. Tuy nhiên hai spike làm kết quả trung bình không đạt.

Run B chỉ đọc `ps` ở đầu và cuối sau 20 giây warm-up, có heartbeat shell không attach vào process. CPU time tăng từ 0,19 lên 12,83 giây trong đúng 5 phút, tương đương khoảng 4,21% của một CPU core. RSS cuối kỳ vượt mục tiêu 60 MB trong spec.

Run C được dùng để kiểm tra nhanh sau rebuild và cho thấy không có busy loop liên tục, nhưng không giải thích được spike dài ở run B.

### Các điều kiện đã xác nhận

- Không có `Timer.publish(every:)` hoặc repeating timer trong code path hiện tại.
- Scheduler production chỉ giữ một Swift concurrency sleep đến boundary UTC+7 kế tiếp; replacement/cancel/deinit đã có test.
- Unified log của process không có dòng lặp theo giây/phút trong cả hai run 5 phút.
- Popover được đóng trong toàn bộ thời gian đo.

### Gate và bước tiếp theo

M6.4 chưa đạt. Trước khi đóng task hoặc release cần:

1. Chạy signed Release build ngoài DerivedData trong Instruments Energy Log và Time Profiler tối thiểu 5 phút.
2. Bắt đúng stack/call tree tại spike CPU thay vì chỉ sample sau spike.
3. Phân biệt chi phí SwiftUI/MenuBarExtra của Debug build với lifecycle/scheduler work của ứng dụng.
4. Profile allocations/RSS; nếu Release RSS vẫn trên 60 MB, thực hiện yêu cầu điều tra trong spec trước khi cân nhắc shell AppKit.
5. Lặp lại low-impact 5-minute measurement và chỉ đóng gate khi CPU trung bình <= 0,1% hoặc có ADR/waiver được chấp nhận.
