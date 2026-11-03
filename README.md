# Sim School — Mobile landscape

Game HTML/Canvas dành cho điện thoại xoay ngang, chỉnh từ `sim_school_v3.html` người dùng cung cấp.

## Chạy

Mở `index.html` trực tiếp trong trình duyệt, hoặc chạy tại thư mục repository:

```sh
python3 -m http.server 8000
```

Không cần npm, backend, API key hoặc mạng để chơi. Sprite và ảnh nền đã được nhúng trong HTML. `assets/characters/` giữ các sprite và metadata gốc để phát triển tiếp.

## Thay đổi

- Màn bắt đầu mang chủ đề đời sống học sinh, bỏ logo/phím chữ và nội dung Type Run tại màn này. Hoạt động chạy trong sân thể thao vẫn được giữ.
- Bộ nút và HUD dùng khung gọn; icon Canvas có màu riêng theo vật thể (cặp sách xanh, sao vàng, căn tin cam, nhiệm vụ tím), chỉ tô phần biểu tượng trên nền trong suốt để không dính nền ảnh. Joystick trong mờ bên trái, nút tiện ích bên phải.
- Vùng chết joystick, tốc độ analog, chuẩn hóa đi chéo, bước kiểm tra va chạm nhỏ và trượt dọc tường. Bước chân/animation chỉ tiến khi nhân vật thực sự di chuyển.
- Hướng nhìn đi chéo có hysteresis để không giật hướng; không cho ngón tay thứ hai chiếm joystick. Vùng chạm âm thanh màn đầu khớp nút hiển thị.
- Giải phóng điều khiển khi hủy chạm, mất pointer capture, mất focus, ẩn trang hoặc đổi kích thước.
- Tích hợp sáu sheet 1152×640, 9×5 ô 128px trong pack; giữ các nhân vật cũ. Chọn ngoại hình phân trang 5 nhân vật bằng hai mũi tên.
- Thông báo xoay ngang khi dùng điện thoại dọc.

## Kiểm tra đã thực hiện

Chromium/Playwright: bắt đầu → chọn nhân vật → vào sân trường; tải đủ sáu sheet; không có lỗi JavaScript trong luồng kiểm tra. Đi thẳng/chéo cùng quãng đường 17.5px trong 0.1 giây; va chạm tường chặn nhân vật; mất focus và hủy touch trả điều khiển về nghỉ; thông báo xoay ngang hiển thị ở 390×844. Đã xuất và xem ảnh Canvas của màn bắt đầu, chọn nhân vật và sân trường.

Chưa kiểm tra trên thiết bị Android/iOS thật và chưa kiểm thử toàn bộ các minigame có sẵn.
