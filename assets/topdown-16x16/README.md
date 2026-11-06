# Asset top-down 16×16 cho Sim School

Tải từ Kenney ngày 2026-11-06. Hiểu yêu cầu “16bytes” là pixel art có ô 16×16 px.

| Thư mục | Nguồn | Gợi ý sử dụng |
| --- | --- | --- |
| `tiny-town` | https://kenney.nl/assets/tiny-town | Cây, đường đi, hàng rào, nhà và cảnh ngoài trời |
| `roguelike-modern-city` | https://kenney.nl/assets/roguelike-modern-city | Đường phố, công trình và khu vực quanh trường |
| `roguelike-indoors` | https://kenney.nl/assets/roguelike-indoors | Bàn ghế, giá kệ, sàn và đồ trang trí phòng |

Mở `preview.html` để xem ảnh mẫu. Mỗi bộ giữ nguyên ZIP gốc, ảnh Preview/Sample và License.txt. Giấy phép CC0: được dùng, sửa trong dự án cá nhân và thương mại; ghi công Kenney là tùy chọn.

## Dùng trong Canvas

- Tiny Town: `tiny-town/Tilemap/tilemap_packed.png`, 12 cột × 11 hàng, ô 16×16, không có khoảng cách giữa ô.
- Modern City: `roguelike-modern-city/Tilemap/tilemap_packed.png`, 37 cột × 28 hàng, ô 16×16, không có khoảng cách giữa ô.
- Indoors: `roguelike-indoors/Tilesheets/roguelikeIndoor_transparent.png`, 27 cột × 18 hàng, ô 16×16, cách nhau 1 px (bước tọa độ 17 px).
- Các bản `tilemap.png` có khoảng cách 1 px. Tiny Town và Modern City còn có PNG riêng trong `Tiles`.
- Tắt `g.imageSmoothingEnabled` và phóng theo bội số nguyên (2×, 3×, 4×) để giữ pixel sắc nét.
- Đây là asset góc nhìn top-down kiểu RPG: vẫn nhìn thấy mặt trước đồ vật. Hai bộ Roguelike hợp nhau hơn; Tiny Town có bảng màu và tỷ lệ nhân vật khác.

Ví dụ nạp từ `index.html` ở thư mục gốc:

```js
const townTiles = new Image();
townTiles.src = 'assets/topdown-16x16/tiny-town/Tilemap/tilemap_packed.png';
townTiles.onload = () => {
  g.imageSmoothingEnabled = false;
  g.drawImage(townTiles, 0, 0, 16, 16, 100, 100, 48, 48);
};
```

Các asset mới chỉ được thêm vào thư mục, chưa tích hợp vào màn chơi trong `index.html`.
