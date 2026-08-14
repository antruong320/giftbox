# GiftBox Pro V2 — triển khai bằng iPhone

## V2 đã thay đổi gì?
- Bỏ Email OTP.
- Đăng ký bằng Tên + Email + Mật khẩu.
- Đăng nhập bằng Email + Mật khẩu.
- Dashboard thống kê Gift Box, lượt xem, quà đã mở.
- Tạo Gift Box với người nhận, người gửi, tiêu đề, dịp, lời nhắn.
- 5 theme: Rose, Midnight, Gold, Sky, Violet.
- Upload ảnh + nhạc.
- Hẹn giờ mở Gift Box và trang đếm ngược.
- Link/QR riêng cho mỗi Gift Box.
- Người nhận không cần đăng nhập.
- Có xem, sao chép link và xóa Gift Box.

## 1. Supabase
Mở Supabase trên Safari > project hiện tại > SQL Editor.

Chạy toàn bộ file `setup_v2.sql`.

Script này có thể chạy trên database V1 hiện tại: nó giữ bảng `gifts` và thêm các cột V2.

### Authentication
Vào Authentication > Providers > Email.
- Bật Email provider.
- Password sign-in phải được bật.
- Nếu bật Confirm email: người đăng ký phải bấm link xác nhận email trước khi đăng nhập.
- Nếu muốn test nhanh: có thể tắt Confirm email trong giai đoạn thử nghiệm.

## 2. config.js
Giữ Project URL + Publishable key hiện tại.

Không bao giờ đưa `service_role`, `sb_secret_...` hoặc Secret key vào website.

## 3. GitHub
Trong repository GiftBox, thay/cập nhật 4 file:
- `index.html`
- `gift.html`
- `config.js`
- `setup_v2.sql` (có thể giữ để backup; website không chạy trực tiếp file này)

Cloudflare Pages sẽ tự deploy lại khi GitHub thay đổi.

## 4. Luồng sử dụng
1. Mở domain GiftBox Pro.
2. Chọn Đăng ký.
3. Nhập tên, email, mật khẩu.
4. Xác nhận email nếu Supabase đang yêu cầu.
5. Đăng nhập.
6. Bấm `Tạo Gift Box`.
7. Chọn theme, ảnh, nhạc, lời chúc và thời gian mở.
8. Tạo Gift Box.
9. Copy link hoặc QR gửi người nhận.
10. Người nhận mở link; nếu chưa đến giờ sẽ thấy countdown.

## Gợi ý giai đoạn tiếp theo
V3 có thể bổ sung chỉnh sửa Gift Box, ảnh cover/video, nhiều ảnh, template theo dịp, mã QR tải về, chia sẻ Zalo/Messenger, custom slug, gói Free/Pro, shop sản phẩm thật và thanh toán.
