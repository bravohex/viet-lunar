# Chính sách quyền riêng tư của VietLunar

VietLunar hoạt động hoàn toàn trên máy Mac và không cần tài khoản hay kết nối mạng để xem lịch.

## Dữ liệu được lưu

- Cài đặt hiển thị như định dạng tiêu đề, đồng hồ và ngày bắt đầu tuần được lưu trong `UserDefaults` của ứng dụng.
- Trạng thái “Mở khi đăng nhập” do macOS quản lý qua `SMAppService`; VietLunar không lưu một bản sao làm nguồn sự thật.
- Tệp ngày lễ `.ics` mà bạn chọn trong **Cài đặt > Ngày lễ** được sao chép vào thư mục dữ liệu của ứng dụng (`Application Support/VietLunar/Holidays` trong container của VietLunar); tên hiển thị và nguồn đang chọn được lưu trong `UserDefaults`. VietLunar chỉ đọc đúng các tệp bạn chọn qua hộp thoại mở tệp của macOS (quyền “user-selected read-only” của sandbox) và không đọc thư mục nào khác.
- Bản MVP không có sự kiện, cơ sở dữ liệu người dùng, đồng bộ đám mây hoặc thông báo từ máy chủ.

## Dữ liệu không được thu thập

VietLunar không tích hợp analytics, quảng cáo, crash-reporting bên thứ ba, telemetry, tài khoản, định danh quảng cáo hoặc SDK mạng. Ứng dụng không yêu cầu quyền Danh bạ, Vị trí hay Lịch hệ thống.

Không có dữ liệu cá nhân nào được gửi ra ngoài máy Mac. Project không khai báo outbound network entitlement và không chứa network client trong runtime source.

## Xóa dữ liệu

Gỡ VietLunar sẽ xóa application bundle nhưng macOS có thể giữ preferences. Người dùng kỹ thuật có thể xóa preferences bằng:

```bash
defaults delete com.bravohex.vietlunar
```

Bản sao các tệp ngày lễ đã nhập có thể được xóa bằng nút **Xoá nguồn này** trong **Cài đặt > Ngày lễ**; tệp gốc của bạn không bị thay đổi.

Login-item state có thể được tắt trong VietLunar hoặc tại **Cài đặt hệ thống > Cài đặt chung > Mục đăng nhập**.

## Phạm vi

Chính sách này áp dụng cho MVP offline hiện tại. Bất kỳ tính năng mạng, analytics, cloud sync hoặc tích hợp dữ liệu bên ngoài nào trong tương lai phải cập nhật chính sách và yêu cầu review riêng trước khi phát hành.
