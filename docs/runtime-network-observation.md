# VietLunar runtime network observation

**Ngày đo:** 2026-07-20

**Môi trường:** Mac mini Apple Silicon, macOS 26.5.2, Developer ID signed Release app chạy ngoài Xcode

## Cấu hình

- App Sandbox và Hardened Runtime bật.
- Release entitlements chỉ có `com.apple.security.app-sandbox`; không có outbound network entitlement.
- App ở trạng thái idle, popover đóng, mạng của máy vẫn bật.

## Phép đo

Tiến trình app được chọn trực tiếp theo PID. Hai kiểm tra độc lập được dùng:

```bash
nettop -P -L 60 -s 1 -p <PID> -n -x
lsof -nP -a -p <PID> -i
```

Kết quả:

- `nettop` hoàn thành 60 mẫu cách nhau một giây; mọi mẫu chỉ có CSV header, không có process/socket row và không có byte vào/ra.
- `lsof` trước và sau cửa sổ đo không trả TCP/UDP/Internet socket nào cho tiến trình.
- App vẫn chạy bình thường trong suốt phép đo và được dừng sạch sau khi kết thúc.

## Kết luận và giới hạn

Kết hợp runtime observation, source/package scan và Release entitlement check đủ để đóng acceptance P3 “không có network traffic bất ngờ” cho build hiện tại.

Phép đo này không tắt adapter mạng của máy. Vì vậy functional acceptance F12 “app hoạt động khi networking bị tắt” vẫn cần một lần chạy thủ công với network thực sự disabled; A6 không dùng kết quả zero-traffic để thay thế yêu cầu đó.
