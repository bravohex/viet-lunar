# VietLunar distribution guide

## Release prerequisites

- Xcode hỗ trợ Swift 6 và macOS 13 deployment target.
- Chứng thư `Developer ID Application` hợp lệ trong keychain.
- Apple Developer Team ID.
- `notarytool` keychain profile đã cấu hình nếu phát hành ngoài nội bộ.
- Toàn bộ release gates trong `docs/VietLunar_WBS.md` đã đóng hoặc có waiver được duyệt.

Không notarize hoặc phân phối candidate build khi independent accuracy/license gates còn mở.

## Reproducible verification

Từ repository root:

```bash
./scripts/verify_reference_data.sh
ruby Tools/ProjectGenerator/generate_project.rb
./scripts/test.sh
./scripts/benchmark.sh
```

Project generation phải byte-identical khi chạy lặp lại. Full scheme và clean Release build phải đạt trước khi archive.

## Signed archive

Đặt Team ID thực tế vào biến môi trường, không commit certificate identity hoặc credential vào repo:

```bash
export VIETLUNAR_TEAM_ID="YOUR_TEAM_ID"
xcodebuild archive \
  -project VietLunar.xcodeproj \
  -scheme VietLunar \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath .build/VietLunar.xcarchive \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  DEVELOPMENT_TEAM="$VIETLUNAR_TEAM_ID"
```

Kiểm tra bundle và entitlements:

```bash
APP_PATH=".build/VietLunar.xcarchive/Products/Applications/VietLunar.app"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -d --entitlements :- "$APP_PATH"
```

Release app phải có sandbox entitlement, hardened runtime, cùng Team ID cho app/frameworks, không có `get-task-allow` và không có outbound network entitlement.

## Notarization

Tạo archive upload không làm mất resource fork:

```bash
ditto -c -k --keepParent "$APP_PATH" .build/VietLunar-notarize.zip
xcrun notarytool submit \
  .build/VietLunar-notarize.zip \
  --keychain-profile "YOUR_NOTARY_PROFILE" \
  --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"
```

Không commit archive, zip, certificate, key, Team credential hoặc notary profile.

## Installed login-item checklist

Chỉ chạy sau khi có quyền thay đổi trạng thái hệ thống:

1. Copy signed/stapled `VietLunar.app` vào `/Applications`.
2. Launch app; xác nhận không có Dock icon và không tự mở popover.
3. Bật **Mở VietLunar khi đăng nhập**; đối chiếu trạng thái macOS.
4. Nếu `requiresApproval`, dùng action mở Login Items và xác nhận hướng dẫn đúng.
5. Tắt lại; xác nhận trạng thái `disabled` và app vẫn đang chạy bình thường.
6. Dọn login-item state trước khi xóa test app.

Mỗi lần release cần lưu phiên bản, build, checksum artifact, kết quả notarization và checklist vào release record; không lưu credential.
