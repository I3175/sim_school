# Asset nhân vật theo map

- `school/` có 20 NPC của Trường Bình Minh, gồm cả các phòng trong trường.
- `farm/` có 12 NPC của Mầm Xanh, gồm cả Bác Năm trong nhà kính.

Mỗi thư mục NPC có cấu trúc:

```text
<map>/<id>/
├── data/profile.json
├── portraits/default.png
└── sprites/
    ├── idle.png
    └── walk.png
```

`profile.json` lưu tên, mã cảnh, vị trí chân tính theo ô 16 px, thiết kế và hai câu thoại. `idle.png` có 2 cột và `walk.png` có 4 cột. Mỗi frame 32×32 px, bốn hàng lần lượt là xuống, lên, phải, trái. Chân dung vẽ ở kích thước 64×64 px.

Sửa hồ sơ rồi chạy `python game/draw-npcs.py` từ thư mục dự án với Pillow để tạo lại PNG và danh mục JS cho game. Thư mục `legacy/` trong một số NPC farm lưu bản hình cũ. Sáu sheet `sprite_A…F` ở thư mục gốc là nhân vật dùng chung cho các bản chơi.
