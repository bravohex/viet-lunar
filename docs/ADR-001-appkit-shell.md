# ADR-001 — AppKit shell cho menu-bar lifecycle

- **Trạng thái:** Đã triển khai
- **Ngày:** 2026-07-20
- **Phạm vi:** Lớp vỏ ứng dụng macOS; không đổi calendar core

## Bối cảnh

SwiftUI `MenuBarExtra` đã đáp ứng functional/UI tests nhưng signed Release RSS tại khoảng 30 giây lặp lại ở 66.976–70.000 KB, vượt hard-review threshold 60 MB. Việc trì hoãn month grid và login-item query ở A8 không giải quyết resident memory. Spec mục 12.2 và Risk 5 cho phép đánh giá fallback `NSStatusItem` + `NSPopover` khi SwiftUI shell vượt ngưỡng.

## Quyết định

Dùng `NSApplicationDelegate`/`NSStatusItem` làm lifecycle và menu-bar shell. `NSPopover` và Settings window chứa lại đúng các SwiftUI content views hiện có qua `NSHostingController`, nhưng chỉ được tạo khi người dùng mở lần đầu.

Các invariant được giữ:

- live snapshot và menu title đúng ngay khi launch;
- one-shot boundary scheduler vẫn hoạt động khi popover đóng;
- `AppState` tiếp tục ở MainActor;
- Core không import SwiftUI/AppKit;
- app vẫn là accessory/background app, có Settings và Quit rõ ràng;
- không thêm runtime dependency hoặc polling.

## Hệ quả

- RSS 30 giây giảm xuống 32.816–42.384 KB, qua hard-review threshold 60 MB nhưng chưa ổn định dưới target 35 MB.
- App Launch initial frame giảm từ 951,10 ms xuống range 718,08–888,14 ms; median 829,33 ms vẫn vượt hard threshold 800 ms.
- Popover cần clamp vào `NSScreen.visibleFrame` sau khi AppKit tạo window để ổn định trên cấu hình thanh menu/màn hình hiện tại.
- Functional/UI behavior được bảo vệ bằng full scheme và UI flow lặp; M8.2/P5 vẫn mở. ADR này ghi quyết định kiến trúc, không chấp thuận waiver hiệu năng.
