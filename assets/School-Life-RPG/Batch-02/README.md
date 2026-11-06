# School Life RPG — Đợt 2: Công trình
Nguồn: ../../school_building.md. Ngày tạo: 06/11/2026. Công cụ: ImageGen tích hợp; prompt đầy đủ trong PROMPTS.json.

Đã tạo 32 mẫu: 16 ngoại thất công trình và 16 đồ vật phục vụ nội thất. Mở preview.html để xem và tìm tên. Hai PNG gốc RGBA 1254×1254, có alpha. atlas.json chứa tọa độ từng mẫu; riêng atlas công trình dùng các ranh giới hàng 0/350/700/1005/1254 theo bố cục ảnh, không chia hàng đều để tránh cắt bậc thềm.

layout-specs.json lưu đúng kích thước 11 khu vực được đề xuất trong tài liệu, cả tile và pixel (16 px/tile). Đây là thông số bản đồ dự kiến, KHÔNG phải kích thước sprite ngoại thất; chưa dựng các bản đồ này. Không tự suy ra kích thước tòa nhà chính vì tài liệu chưa nêu.

## Phạm vi và phần còn thiếu
- Đây là các mẫu tĩnh phong cách pixel-art độ phân giải cao, chưa chuẩn native 16×16/32×32.
- Chưa tách mái/tường/cửa thành module; chưa có tile nền liền mạch hoặc autotile.
- Chưa có nội thất đầy đủ cho từng công trình, state mở/đóng, animation nước/cờ, collision hoặc nhiều hướng nhìn.
- Ký túc xá tạo 4 tầng theo khoảng 3–5 tầng trong tài liệu.
- Các biển tên để trống hoặc dùng biểu tượng; tên tiếng Việt hiển thị trong preview/JSON, chưa in lên PNG.
- Một số props là cụm: bàn hiệu trưởng kèm ghế, bàn họp kèm ghế, sân khấu kèm rèm. Không coi các thành phần đó là sprite rời.
- Tỷ lệ giữa các công trình trong atlas được thu gọn để xem; cần chọn display size riêng trong game.
- Giữ nguyên school_building.md và index.html. Xem ../PROGRESS.md cho toàn bộ kế hoạch.

