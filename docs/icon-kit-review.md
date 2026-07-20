# VietLunar Icon Kit review

**Ngày rà soát:** 2026-07-20

**Nguồn đầu vào:** `/Users/tuanlm/Workspaces/my-tools/VietLunar_Icon_Kit`

## Kết luận

Icon kit 1.0.0 dùng được cho ứng dụng. Artwork được tạo riêng cho VietLunar và usage notice cho phép sử dụng, sửa đổi, sao chép và phân phối cùng ứng dụng. Không có logo, font hoặc artwork bên thứ ba được khai báo.

Toàn bộ 785 file (không tính `.DS_Store`) đã được kiểm tra:

- `SHA256SUMS.txt` xác minh thành công toàn bộ entry;
- 72 JSON parse hợp lệ, manifest có đúng 64 icon và không trùng name/asset name;
- 68 SVG là XML hợp lệ, feature SVG không nhúng script/image/font hoặc external reference;
- 64 icon tính năng có đủ SVG/PDF và 448 PNG đúng bảy kích thước 16/20/24/32/48/64/128;
- 64 Xcode imageset trùng checksum với PDF nguồn, giữ vector representation và template rendering;
- 3 menu-bar icon có bản SVG/PDF/PNG, hiển thị rõ ở Light/Dark preview;
- app icon có đủ 10 macOS rendition từ 16×16 đến 512×512@2x và bản 1024 px có alpha cho phần bo góc/shadow;
- các PDF mẫu là một trang, không mã hóa và giữ vector.

## Phần được tích hợp

Chỉ các asset có vị trí sử dụng thật trong MVP được đưa vào `App/Resources/Assets.xcassets`:

| Asset | Vị trí dùng |
|---|---|
| `AppIcon` | App icon trong bundle macOS |
| `VLMenuBarLunar` | Chế độ menu bar chỉ hiển thị biểu tượng |
| `VLPrevious`, `VLNext` | Điều hướng tháng |
| `VLToday`, `VLSettings`, `VLQuit` | Footer của calendar popover |
| `VLSettings`, `VLInfo` | Hai tab trong cửa sổ Settings |

Phần chọn lọc gồm 26 file, khoảng 256 KB trước khi asset compiler đóng gói. Icon template lấy màu từ ngữ cảnh để macOS tự xử lý Light/Dark Mode; text và accessibility label hiện có vẫn được giữ.

## Phần chưa tích hợp

Các icon event, reminder, recurrence, notification, import/export, backup/restore và menu-bar event/alert chưa được copy. Những tính năng này nằm ngoài MVP hiện tại; đóng gói sớm sẽ tăng bundle và tạo API asset chưa có consumer.

SVG master, PNG preview, HTML gallery, ICNS và full Swift enum cũng không được copy:

- Xcode build dùng appiconset thay vì ICNS thủ công;
- PDF vector trong asset catalog phù hợp hơn PNG cho SwiftUI/AppKit;
- helper Swift gốc có 64 case nhưng app chỉ cần sáu feature icon và một menu icon, nên dùng enum rút gọn để compiler kiểm tra tên mà không quảng bá feature chưa triển khai.

Khi event module E0–E5 được đưa vào phạm vi, từng icon tương ứng cần được thêm cùng task triển khai consumer và accessibility test của tính năng đó.

## Xác minh sau tích hợp

- Project generator chạy hai lần cho checksum `project.pbxproj` byte-identical.
- Asset compiler sinh `AppIcon.icns`, `Assets.car` và `CFBundleIconName=AppIcon`; tám asset đã chọn đều có trong compiled catalog.
- Full automated scheme đạt 98/98, không fail hoặc skip; UI flow xác nhận các nút có icon vẫn tồn tại và thao tác được.
- Developer ID signed Release là universal arm64/x86_64, deep signature hợp lệ, chỉ embed Core framework và launch được ngoài Xcode.
- Release bundle có kích thước 2.516 KB, tăng 232 KB so với baseline trước icon và vẫn đạt target 10 MB.
