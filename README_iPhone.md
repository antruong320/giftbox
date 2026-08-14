# GiftBox V1 — triển khai chỉ bằng iPhone

Mục tiêu:
- Bạn tạo quà trên iPhone.
- Mỗi quà có UUID riêng.
- Link ví dụ: `https://TEN-MIEN-CUA-BAN.pages.dev/gift.html?id=...`
- Người nhận mở link trên iPhone/Android mà không cần đăng nhập.
- Ảnh/nhạc lưu trên Supabase Storage.
- Dữ liệu quà lưu trên Supabase Postgres.
- Người tạo đăng nhập bằng email OTP.

## Bước 1 — tạo Supabase
Mở https://supabase.com/ trên Safari và tạo project.
Sau khi tạo xong, vào SQL Editor và chạy toàn bộ `setup.sql`.

Sau đó vào Project > Connect hoặc Settings > API Keys.
Lấy:
- Project URL
- Publishable key

Chỉ dùng Publishable key trong `config.js`. Không bao giờ đưa Secret key vào website.

## Bước 2 — sửa config.js
Mở `config.js`, thay:
SUPABASE_URL: "PASTE_YOUR_SUPABASE_URL_HERE"
SUPABASE_KEY: "PASTE_YOUR_SUPABASE_PUBLISHABLE_KEY_HERE"

## Bước 3 — đưa website lên Cloudflare Pages
Cách đơn giản trên iPhone:
1. Tạo tài khoản GitHub.
2. Tạo repository mới, ví dụ `giftbox`.
3. Upload 3 file:
   - index.html
   - gift.html
   - config.js
4. Vào Cloudflare Pages.
5. Create application > Pages > Import existing Git repository.
6. Chọn repository `giftbox`.
7. Build command: `exit 0`
8. Build output directory: `/` hoặc thư mục chứa các file.
9. Deploy.

Cloudflare Pages cấp cho bạn một domain `*.pages.dev`.

## Bước 4 — dùng
Mở domain của bạn:
- Đăng nhập bằng email OTP.
- Nhập người nhận + lời nhắn.
- Chọn ảnh/nhạc.
- Bấm Tạo Gift Box.
- Hệ thống tạo link riêng.
- Bấm Sao chép link và gửi qua Zalo/Messenger/iMessage.

## Lưu ý bảo mật
- `config.js` chứa Publishable key nên có thể xuất hiện ở trình duyệt.
- Không đưa `sb_secret_...` hoặc `service_role` vào website.
- RLS và function public trong `setup.sql` được thiết kế để người nhận chỉ lấy đúng món quà theo ID.
- Bản V1 giới hạn file 6MB để upload ổn định trên điện thoại.
