# Làng Sao Mai · Bộ hình ảnh và giao diện

Mở `res://scenes/ui/ui_gallery.tscn` trong Godot 4.7 và chạy scene bằng F6. Dùng nút mũi tên, Page Up/Page Down hoặc LB/RB để đổi màn. Esc trở về tiêu đề, F1 mở sổ mẫu widget. Gallery dùng khung 320×180 và bộ lọc Nearest.

- [Ảnh tổng hợp 21 màn](sao-mai-art/gallery.png)
- [Nông trại Mầm Xanh có thể đi lại trong trình duyệt](sao-mai-art/farm-preview.html)
- [Kết quả kiểm tra các đích tương tác trong trình duyệt](sao-mai-art/scene-snapshot.json)
- [Prompt và nguồn ảnh](../assets/art/sao_mai/source/image-gen-prompts.json) · [Kích thước, neo và SHA-256](../assets/art/sao_mai/source/image-assets.json)

## Phạm vi

| Hạng mục | Kết quả |
| --- | --- |
| Nông trại Mầm Xanh | Bản đồ Godot 80×60 ô, tile 16×16, nhà, cây ăn trái, đá rêu và hòm. Scene chính đọc gói map mới. Vị trí spawn, vùng va chạm và vị trí tương tác được lấy theo bố cục nông trại hiện có. |
| Giao diện | 21 màn duyệt, gồm tiêu đề, HUD, chín thẻ sổ tay, hội thoại, cửa hàng, học tập, câu cá, chiến đấu, tổng kết, tải game, tạo nhân vật, cutscene và sổ mẫu widget. Màn học tập có bảy bố cục câu hỏi. Cài đặt minh họa ba bố cục theo cỡ chữ. |
| Bộ UI | Theme Godot và khung 9-slice biên 3 px, 22 icon cơ bản, sáu icon vật phẩm 16×16 đã gắn vào dữ liệu game, bốn font bitmap gồm tiếng Việt 8/10/12 px và bộ số 5×7. |
| Ảnh từ Image Gen | Nền bình minh 320×180, bốn vật thể có alpha và một chân dung Dì Năm 48×48. Tất cả ảnh sinh dùng Image Gen tích hợp của Codex. Công cụ trả ảnh và đường dẫn. Phiên bản model và chi phí cụ thể không có trong kết quả. |
| Hình vẽ bằng mã | Tile nền, khung UI, icon và font là tài nguyên vẽ theo lưới. Mã nguồn PixelSpec, material và các script dựng nằm cùng dự án. |

Gallery dùng dữ liệu mẫu để duyệt bố cục, focus, các kiểu câu hỏi và cỡ chữ. Tích hợp gameplay của đợt này gồm nông trại và sáu icon vật phẩm. Nền tiêu đề hiện là một lớp tĩnh. Parallax bốn lớp, biến thể mùa/giờ, chân dung và biểu cảm cho dàn NPC, cùng việc gắn toàn bộ giao diện vào luồng gameplay là các phần còn mở. Bản đồ vùng trong gallery là sơ đồ kết nối. Kiểm chứng tuyến đường áp dụng cho tám điểm tương tác bên trong nông trại.

## Kiểm tra

- Godot 4.7.2 · 48/48 bài kiểm thử GUT đạt, gồm khung nhìn của 21 màn, bảy ví dụ câu hỏi và bộ ký tự tiếng Việt U+1EA0–U+1EF9.
- Code Art 2D · 128 tile Wang. Đối chiếu 4.347.904 pixel ở đường nối, sai khác 0. Kiểm tra panel, icon và vật phẩm đạt.
- Generate 2D Map · Gói map và SHA-256 hợp lệ. Cả 8 đích tương tác đến được từ spawn, 0 đích không đến được, 0 khe hẹp. Preview chạy kiểm tra trong Chrome.
- Generate 2D Sprite · Chân dung Dì Năm dùng alpha gốc, chuẩn hóa thành 48×48. QC đạt.

## Dựng lại bộ hình

Chạy lần lượt `tools/art/build_sao_mai_kit.py`, `tools/art/build_sao_mai_theme.py` và `tools/art/build_sao_mai_farm.py` bằng Python của Sprite Forge. Script cuối dùng ba ảnh gốc đã lưu trong `assets/art/sao_mai/source` và không gọi dịch vụ tạo ảnh.
