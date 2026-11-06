# Farm Workshop — bộ bổ sung 16 đồ vật farm

Tạo ngày 06/11/2026 bằng công cụ ImageGen tích hợp. Tham chiếu định hướng: https://maevedevs.itch.io/farm-rpg — pixel art RPG dễ thương, màu tươi sáng, chủ đề đời sống nông trại. Các thiết kế được tạo mới qua prompt; không trích sprite của bộ Maeve và không phải sản phẩm chính thức của Maeve.

## File

- `farm-workshop-atlas.png`: atlas gốc RGBA 1254×1254, 4 cột × 4 hàng, 16 đồ vật.
- `atlas.json`: tên, tọa độ và kích thước ô để vẽ bằng Canvas.
- `preview.html`: xem từng ô trên nền cỏ/đất/tối/sáng; mở trực tiếp được.
- `PROMPT.txt`: prompt đầy đủ đã dùng với ImageGen tích hợp, không dùng API/CLI.

## Nội dung

Nhà kính, bàn làm vườn, thùng ủ phân, thùng nước mưa, máy ép táo, bếp nấu mứt, thùng nuôi ong, khay ươm, quầy nông sản, xe chở bí, bù nhìn, giá dụng cụ, thùng dâu, giỏ cà rốt, bình tưới và bao hạt giống.

## Phạm vi sử dụng kỹ thuật

Đây là bộ đồ vật tĩnh dạng atlas, không có nhân vật, animation hay terrain tự nối. Ảnh sinh bằng AI có phong cách pixel-art nhưng **không phải native pixel art 16×16/32×32**. Kích thước thực tế là 1254×1254, khác kích thước 1024 đề nghị trong prompt; manifest dùng kích thước thực tế. Các ô 313 hoặc 314 px được chia theo lưới 4×4. Viền có pixel alpha bán trong suốt. Cần tinh chỉnh pixel và tỷ lệ nếu muốn khớp chính xác bộ Maeve hoặc lưới 16 px; không coi bản này là tileset thay thế trực tiếp cho bản Maeve.

Mở trang preview để kiểm tra các ô cắt và độ rõ ở kích thước nhỏ. Mỗi sprite hiện cùng kích thước ô, nhưng kích thước hiển thị trong game nên tùy đồ vật: nhà kính lớn hơn bình tưới. Anchor trong manifest là tâm đáy của ô, chưa phải chân va chạm đã tinh chỉnh. Chưa tích hợp vào `index.html`.

Ví dụ với atlas đã tải và một frame lấy từ JSON:

```js
g.imageSmoothingEnabled = false;
g.drawImage(image, frame.x, frame.y, frame.width, frame.height,
            worldX - displaySize / 2, worldY - displaySize,
            displaySize, displaySize);
```
