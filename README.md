# VietLunar

VietLunar là ứng dụng macOS native, chạy hoàn toàn offline trên menu bar để hiển thị lịch âm Việt Nam. MVP dùng Swift 6, SwiftUI `MenuBarExtra`, calculation convention UTC+7 và không có runtime dependency ngoài Apple frameworks.

## Trạng thái

Project đã có app/core/infrastructure targets, unit/UI test targets và menu-bar shell với nhãn `ÂL`. Calendar engine và giao diện lịch sẽ được triển khai tuần tự theo [WBS](docs/VietLunar_WBS.md).

## Yêu cầu phát triển

- macOS 13.0 trở lên.
- Xcode 26 hoặc một Xcode stable hỗ trợ Swift 6.
- Ruby gem `xcodeproj` chỉ cần khi tái tạo project file; đây không phải runtime dependency.

## Build và test

Chạy toàn bộ build và test bằng một lệnh:

```bash
./scripts/test.sh
```

Tái tạo Xcode project sau khi thêm/xóa source file:

```bash
ruby Tools/ProjectGenerator/generate_project.rb
```

Project generator là công cụ phát triển. Generated `VietLunar.xcodeproj` vẫn được commit để người dùng có thể mở và build ngay bằng Xcode.

## Kiến trúc

- `App/`: SwiftUI application shell và giao diện.
- `Sources/Core/`: date/lunar/Can-Chi domain thuần Swift, không phụ thuộc UI.
- `Sources/Infrastructure/`: clock, lifecycle, preferences, login item và logging adapters.
- `Tests/`: unit tests và UI smoke tests.
- `Tools/`: development-only generators.
- `docs/`: product spec, implementation plan, WBS và curated regression vectors.

## Quy ước lịch

- Khoảng ngày production dự kiến: `1800-01-01...2199-12-31`.
- Ngày lịch âm hiện tại được tính theo UTC+7.
- Dữ liệu trước 1976 là proleptic modern astronomical Vietnamese calendar, không được mô tả như lịch chính thức lịch sử.
- App trả typed error ngoài khoảng được xác minh; không xấp xỉ.

Reference data, provenance và exhaustive accuracy tests sẽ được hoàn thiện ở milestone M2 trước khi phát hành.
