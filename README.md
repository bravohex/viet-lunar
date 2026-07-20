# VietLunar

VietLunar là ứng dụng macOS native, chạy hoàn toàn offline trên menu bar để hiển thị lịch âm Việt Nam. MVP dùng Swift 6, SwiftUI `MenuBarExtra`, calculation convention UTC+7 và không có runtime dependency ngoài Apple frameworks.

## Trạng thái

Ứng dụng MVP đã có menu-bar calendar, Can–Chi, Settings, preferences, lifecycle scheduler và `SMAppService` adapter. Full automated scheme hiện đạt 96/96 tests, nhưng build chưa release-ready vì các gate trong [acceptance review](docs/acceptance-review.md) và [WBS](docs/VietLunar_WBS.md) vẫn còn mở.

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

Chạy microbenchmark Core ở cấu hình optimized:

```bash
./scripts/benchmark.sh
```

Project generator là công cụ phát triển. Generated `VietLunar.xcodeproj` vẫn được commit để người dùng có thể mở và build ngay bằng Xcode.

Hướng dẫn ký/notarize nằm tại [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md). Không phân phối candidate build khi WBS còn release blocker.

## Kiến trúc

- `App/`: SwiftUI application shell và giao diện.
- `Sources/Core/`: date/lunar/Can-Chi domain thuần Swift, không phụ thuộc UI.
- `Sources/Infrastructure/`: clock, lifecycle, preferences, login item và logging adapters.
- `Tests/`: unit tests và UI smoke tests.
- `Tools/`: development-only generators.
- `docs/`: product spec, implementation plan, WBS và curated regression vectors.

## Quy ước lịch

- Khoảng ngày runtime: `1800-01-01...2199-12-31`.
- Ngày lịch âm hiện tại được tính theo UTC+7.
- Dữ liệu trước 1976 là proleptic modern astronomical Vietnamese calendar, không được mô tả như lịch chính thức lịch sử.
- App trả typed error ngoài khoảng được xác minh; không xấp xỉ.

Generated table đã có checksum và exhaustive round-trip, nhưng independent conformance/2033 evidence vẫn chưa đạt. Xem [ReferenceData/README.md](ReferenceData/README.md), [NOTICE.md](NOTICE.md) và [PRIVACY.md](PRIVACY.md).
