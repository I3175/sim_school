# School & Sprout — Desktop Playtest

Bản game HTML/Canvas cho máy tính, gồm hai map trường học và nông trại, dùng các asset đã tạo trong dự án.

## Chạy

Nhấp đúp **RUN_GAME.cmd** (cần Python 3). Hoặc:

```powershell
python -m http.server 8937 --bind 127.0.0.1
```

Mở **http://127.0.0.1:8937**. Không cần npm, backend, API key hoặc internet để chơi.

## Điều khiển

WASD / mũi tên để đi, Shift chạy, E tương tác. Phím 1/2/3/4 chọn bàn tay, hạt giống, bình tưới và cần câu. J mở nhật ký, nơi có bản đồ nhỏ và nút đổi khu vực. Bạn cũng có thể đi xe đưa đón để đổi map. Esc đóng menu hoặc tạm dừng.

## Có thể test

- Trường: tiết học trắc nghiệm, đọc sách, bài tập phản xạ tại gym, căn tin, phòng nghệ thuật, sân chơi và nghỉ sang ngày mới.
- Farm: 9 luống gieo–tưới–lớn–thu hoạch, mua hạt, bán nông sản, bón phân, lấy mật, chế biến mứt/nước ép.
- Nhật ký 6 nhiệm vụ liên kết hai map, xu, kiến thức, cấp độ, mini-map, camera, va chạm, tự lưu và tải lại tiến độ.
- Animation nhân vật idle/walk/run, NPC đi lại, cây đung đưa, nước, ong, hơi bếp và particle mùa/hành động.

## Đặt mùa trực tiếp trong code

Sửa `season` trong **game/config.js** thành `spring`, `summer`, `autumn` hoặc `winter`, rồi tải lại trang. Mùa ảnh hưởng màu cảnh, hiệu ứng, cây trồng, tốc độ lớn và giá bán. Không có nút đổi mùa trong giao diện. Save không ghi đè mùa đã cấu hình.

Hai map ngoài trời kết nối với 14 cảnh nội thất. Dùng E trước cửa để vào phòng và trên thảm lối ra để quay lại. Xem **game/PLAYTEST.md** để biết luồng chơi và kiểm thử.

## File chính

- `index.html`: giao diện desktop.
- `game/style.css`: bố cục desktop.
- `game/config.js`: cấu hình mùa, thời gian, tốc độ.
- `game/assets.js`: đường dẫn và tọa độ atlas.
- `game/core.js`: trạng thái, cây trồng, kinh tế, va chạm.
- `game/scenes.js`: dữ liệu hai map, phòng, cửa và vùng va chạm.
- `game/game.js`: camera, animation, chuyển cảnh và tương tác.
- `legacy-mobile.html`, `README-mobile.md`: bản mobile trước khi thay giao diện.

## Kiểm tra

`node game/test-core.cjs` kiểm thử logic. `node game/test-browser.cjs` kiểm thử trên Chrome/Playwright với server cổng 8937. Đã qua hai map, 6 nhiệm vụ, save/reload, pause, bốn mùa, màn hình 1280px và không có lỗi JavaScript/tải asset. Chi tiết thư viện kiểm thử trong game/PLAYTEST.md.
