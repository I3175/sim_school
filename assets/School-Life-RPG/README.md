# School Life RPG — đợt 1

Tạo mới theo `../cozy-farm-school/school_asset.md`, ngày 06/11/2026. Người dùng chọn làm toàn bộ theo từng đợt. Đợt này cung cấp **64 mẫu đồ vật tĩnh trong 4 atlas**, không phải toàn bộ danh sách đã hoàn thiện.

Mở `preview.html` trực tiếp để xem, tìm tên, lọc nhóm và thử nền sáng/tối.

| Atlas | Số mẫu | Nội dung |
| --- | --- | --- |
| Tilesets/Classroom/classroom.png | 16 | Bàn ghế, bảng, sách, máy chiếu, đồng hồ, quạt, điều hòa, cửa |
| Tilesets/SpecialRooms/special-rooms.png | 16 | Thư viện, phòng thí nghiệm, nghệ thuật, thể dục |
| Tilesets/CafeteriaHallway/cafeteria-hallway.png | 16 | Nội thất căn tin/hành lang và đồ ăn |
| Tilesets/Outdoor/outdoor.png | 16 | Cổng, cây, sân chơi, đường/cỏ và phương tiện |

## Thông số thực tế

- Mỗi PNG gốc: 1254×1254, RGBA có nền trong suốt; lưới 4×4.
- `atlas.json`: 64 ID, tên tiếng Việt và hình chữ nhật cắt theo ô. Các ô rộng/cao 313 hoặc 314 px.
- Công cụ tạo: ImageGen tích hợp. Toàn bộ prompt lưu trong `PROMPTS.json`.
- Chưa thay đổi hay tích hợp vào `index.html`.

## Phần cần chuẩn hóa

Ảnh có phong cách pixel-art nhưng chưa đạt native 16×16/32×32 hoặc 16 pixels per unit trong bản kế hoạch. Viền có alpha bán trong suốt; kích thước đồ vật tương đối và khoảng đệm chưa đồng nhất. Một số nét sát mép ô cần kiểm tra lại khi tách riêng. Metadata hiện mô tả ô trong atlas, không phải bounding box/collision đã tinh chỉnh.

Các vật thể mới có một góc nhìn, chưa có trạng thái mở/đóng hay animation. Đường đi, cỏ và sân bóng là hình mảng tĩnh chứ chưa phải tile nối liền. Không tự động thu nhỏ rồi coi là đã đáp ứng yêu cầu pixel chính xác.

## Sử dụng Canvas

Nạp PNG qua Image, lấy frame từ atlas.json và vẽ với `drawImage`. Tắt imageSmoothingEnabled khi thử ở kích thước nhỏ. Chọn kích thước hiển thị theo vật thể, vì cùng kích thước ô không có nghĩa xe đưa đón và quả bóng có cùng tỷ lệ trong thế giới.

```js
ctx.imageSmoothingEnabled = false;
ctx.drawImage(image, frame.x, frame.y, frame.width, frame.height,
              screenX, screenY, displayWidth, displayHeight);
```

Xem `PROGRESS.md` để biết các mục còn thiếu và kế hoạch các đợt tiếp theo. Không ghi đè hoặc thay đổi danh sách nguồn của bạn.
