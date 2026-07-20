# Independent lunar-oracle audit

**Ngày rà soát:** 2026-07-20

**Kết luận:** chưa có nguồn nào đủ điều kiện đóng M2.5 cho toàn dải 1800–2199.

## Candidate 1 — Hồ Ngọc Đức JavaScript calendar

- URL: `https://www.xemamlich.uhm.vn/JavaScript/amlich-hnd.js`
- Phạm vi công bố: 1800–2199.
- License header: cho phép personal, non-commercial use với copyright notice; không phải giấy phép phân phối thương mại/permissive chung.
- Vai trò tiềm năng: comparison oracle chính xác theo bảng tính sẵn của tác giả.
- Quyết định: không copy code/table và không dùng làm release oracle cho đến khi phạm vi sử dụng của VietLunar được xác nhận là tương thích hoặc có permission/license bổ sung.

Trang rules của cùng tác giả nói rõ thuật toán công khai đã được đơn giản hóa và kém chính xác hơn chương trình online. Vì production generator hiện thực nhóm công thức đơn giản hóa này, code/table online không được giả định là cùng oracle nếu chưa so sánh thật; đồng thời không được sao chép chỉ để vượt gate.

## Candidate 2 — luc-nham/lunar-calendar

- Repository: `https://github.com/luc-nham/lunar-calendar`
- Revision pin: `4385e669613ebea3f9f450d0aa3a6937fde01ae1` (2025-01-11).
- License: MIT.
- Implementation: PHP astronomical converters, không dùng runtime code của VietLunar.
- Cấu hình đối chiếu: Gregorian noon, fixed UTC+7, mỗi ngày trong candidate JSON.

### Kết quả exhaustive

| Dải | Số ngày | Mismatch | Mismatch đầu | Mismatch cuối |
|---|---:|---:|---|---|
| 1800-01-01…2199-12-31 | 146.097 | 13.028 | 1801-01-14 | 2186-04-18 |
| 1976-01-01…2199-12-31 | 81.815 | 476 | 2054-05-07 | 2186-04-18 |

Library còn phát `Undefined array key` trong leap-month path ở một số năm lịch sử. Vì vậy candidate này bị loại khỏi vai trò exhaustive oracle dù license phù hợp.

### Chuỗi 2033

Candidate MIT khớp các mốc đang yêu cầu:

| Ngày dương | Kết quả UTC+7 |
|---|---|
| 2033-11-22 | 01/11/2033 thường |
| 2033-12-21 | 30/11/2033 thường |
| 2033-12-22 | 01/11/2033 nhuận |
| 2034-01-19 | 29/11/2033 nhuận |
| 2034-01-20 | 01/12/2033 thường |

Test provider của repository cũng ghi rõ năm 2033 có leap month 11. Đây là bằng chứng phụ có license rõ, nhưng chưa tự nó đóng M2.6: task này vẫn phụ thuộc M2.5 và yêu cầu hai validations độc lập được chấp thuận.

## Quyết định

1. Giữ M2.5/M2.6 `Bị chặn`; không đổi production table hoặc làm yếu test.
2. Giữ candidate MIT làm 2033 cross-check được pin, không dùng làm exhaustive truth.
3. Cần một dataset/implementation khác đạt toàn bộ 146.097 ngày với quyền sử dụng rõ ràng, hoặc permission rõ cho Ho JavaScript oracle trong phạm vi phát hành dự kiến.
4. Mọi oracle được chấp nhận sau này phải được chạy lại bằng script tái lập, lưu checksum/provenance và review các mismatch trước khi thay đổi production data.
