# GiftBox Pro V3 — iPhone

## Thứ tự cập nhật
1. Supabase > SQL Editor > chạy `setup_v3.sql`.
2. GitHub: thay `index.html` bằng nội dung `index_v3.html`.
3. GitHub: thay `gift.html` bằng nội dung `gift_v3.html`.
4. Giữ nguyên `config.js` đang chứa Supabase URL + Publishable Key của bạn.
5. Chờ Cloudflare deploy lại rồi tạo Gift Box mới để test.

## V3 thêm gì?
- Chọn tối đa 12 ảnh.
- Ảnh được dựng thành bánh ảnh CSS 3D.
- Vuốt trái/phải để xoay 360 độ trên iPhone.
- Hộp quà có thao tác chạm để mở.
- Chuỗi cảnh: hộp quà > bánh ảnh > tim particle > thư lời chúc.
- 6 hiệu ứng: Hearts, Fireworks, Petals, Confetti, Stars, Mixed.
- Nhạc nền, hẹn giờ mở, link/QR vẫn giữ.
- Gift V1/V2 cũ vẫn đọc được: `photo_url` được tự backfill vào `photo_urls`.

## Lưu ý
Đây là CSS 3D + Canvas nên không cần server 3D riêng. Trên điện thoại yếu, không nên dùng ảnh quá lớn; nên nén ảnh trước khi tải lên để mở nhanh hơn.
