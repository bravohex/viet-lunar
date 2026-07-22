# GitHub Release Guide

Push một tag bắt đầu bằng `v` để chạy [release workflow](../.github/workflows/release.yml). Workflow tạo universal `VietLunar.app` đã ký Developer ID, notarize và staple trước khi tự publish GitHub Release.

## Tạo release

Chỉ tạo tag sau khi các release gate trong [acceptance review](acceptance-review.md) và [WBS](VietLunar_WBS.md) đã được phê duyệt.

Public version phải khớp tag. Mỗi release dùng annotated tag có **tag name** `vX.Y.Z`; GitHub Release nhận **release name** tự động theo mẫu `VietLunar vX.Y.Z`. Ví dụ, khi `MARKETING_VERSION` là `0.1.1`:

```bash
TAG_NAME="v0.1.1"
RELEASE_NAME="VietLunar ${TAG_NAME}"

git tag -a "$TAG_NAME" -m "$RELEASE_NAME"
git push origin "$TAG_NAME"
```

Workflow thực hiện theo thứ tự:

1. Xác nhận Xcode 16.4/Swift 6, reference data và full Xcode test scheme.
2. Import Developer ID Application certificate vào keychain tạm thời.
3. Archive universal app cho Apple Silicon và Intel, ký hardened runtime kèm secure timestamp.
4. Kiểm tra bundle ID, version tag, entitlement, chữ ký và hai kiến trúc binary.
5. Gửi app đến Apple notary service, staple ticket và kiểm tra Gatekeeper.
6. Tạo ZIP phát hành cùng SHA-256, rồi tạo hoặc cập nhật GitHub Release.

Với tag `v0.1.1`, Release có các assets:

```text
VietLunar-v0.1.1-macos-universal.zip
VietLunar-v0.1.1-macos-universal.zip.sha256
```

Nếu rerun cùng tag sau khi release đã tồn tại, workflow upload đè hai assets này thay vì tạo release trùng.

## Cấu hình bắt buộc

- Apple Developer Program membership đang hoạt động.
- Developer ID Application certificate được export ra `.p12`, bao gồm cả private key.
- App Store Connect API key có quyền gửi notarization request.
- GitHub Actions được cấp `contents: write`; workflow đã tự yêu cầu quyền này.

Release dùng GitHub Environment **`Configure CICD Release`**. Tạo năm Environment secrets tại **Settings → Environments → Configure CICD Release**:

| Secret | Giá trị |
|---|---|
| `DEVELOPER_ID_CERTIFICATE_BASE64` | File `.p12` Developer ID Application mã hóa Base64. |
| `DEVELOPER_ID_CERTIFICATE_PASSWORD` | Mật khẩu khi export `.p12`. |
| `NOTARY_KEY_ID` | Key ID của App Store Connect API key. |
| `NOTARY_ISSUER_ID` | Issuer ID của App Store Connect API key. |
| `NOTARY_PRIVATE_KEY_BASE64` | Nội dung file `AuthKey_*.p8` mã hóa Base64. |

Developer ID certificate đã mang Apple Team ID, vì vậy không cần thêm `APPLE_TEAM_ID` secret. `GITHUB_TOKEN` cũng do GitHub tự cấp; không tự tạo secret cho token này.

Tạo hai giá trị Base64 trên macOS, không commit file gốc:

```bash
base64 -i "Developer ID Application.p12" | tr -d '\n' | pbcopy
base64 -i "AuthKey_ABC123XYZ.p8" | tr -d '\n' | pbcopy
```

## Release bằng script

Dùng script để chạy toàn bộ đường chuẩn bị release, bao gồm test, set version/build, regenerate Xcode project, commit, annotated tag và push tùy chọn:

```bash
./scripts/release.sh 0.1.2 --push
```

Mặc định build number tự tăng một đơn vị. Đặt build number cụ thể khi cần:

```bash
./scripts/release.sh 0.1.2 --build 42 --push
```

Không truyền `--push` nếu chỉ muốn tạo commit và tag ở local để review trước. Script từ chối chạy khi working tree còn thay đổi, tag đã tồn tại hoặc version không theo dạng `X.Y.Z`.

## Versioning

VietLunar không dùng `Info.plist` nguồn. Xcode generate Info.plist khi build; version nằm trong [project generator](../Tools/ProjectGenerator/generate_project.rb):

| Setting | Mục đích | Ví dụ |
|---|---|---|
| `MARKETING_VERSION` | Version hiển thị cho người dùng và phải khớp tag. | `0.1.1` |
| `CURRENT_PROJECT_VERSION` | Build number nội bộ. | `1` |

Khi tăng version, cập nhật hai giá trị trong generator rồi tái tạo project:

```bash
ruby Tools/ProjectGenerator/generate_project.rb
```

Không sửa trực tiếp `VietLunar.xcodeproj`, vì generator sẽ ghi đè thay đổi đó. Khuyến nghị dùng semantic version: `0.1.1` cho bug fix, `0.2.0` cho feature tương thích và `1.0.0` cho phát hành ổn định đầu tiên.

## Xử lý lỗi thường gặp

- **Secret rỗng:** kiểm tra workflow job vẫn có `environment: Configure CICD Release`; Environment secrets không tự xuất hiện nếu job không tham chiếu Environment đó.
- **`SWIFT_VERSION 6.0 is unsupported`:** runner phải là `macos-15` với Xcode 16.4; không đổi về `macos-14`/Xcode 15.4.
- **Notarization fail:** mở log từ `notarytool`, sửa lỗi ký/entitlement rồi tạo một tag release mới khớp version mới.

Không thay đổi app sau notarization: mọi thay đổi đều làm chữ ký không còn hợp lệ và phải notarize lại.
