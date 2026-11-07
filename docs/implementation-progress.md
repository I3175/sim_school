# Tiến độ Làng Sao Mai

Nguồn đặc tả: `Game Design Document & Master Prompt.md`. Thực hiện từng hệ thống theo mục 15.5; mỗi hệ thống có scene test, GUT và ghi chú API trước khi chuyển tiếp.

| Mốc | Phạm vi | Trạng thái |
| --- | --- | --- |
| M0 | Dự án, autoload, pixel-perfect, CI/test | Hoàn thành kiểm thử local; CI chưa chạy trên GitHub |
| M1 | Player ghép lớp, tilemap, camera, Y-sort | Chưa làm |
| M2 | Đồng hồ, mùa, thời tiết | Chưa làm |
| M3 | Item, inventory, hotbar, rương, menu | Chưa làm |
| M4 | Trồng–thu–bán | Chưa làm |
| M5 | Tương tác, portal, công trình, chuyển map | Chưa làm |
| M6 | NPC, lịch, hội thoại, shop, hữu nghị | Chưa làm |
| M7 | Nhiệm vụ, nhật ký, 8 loại quest | Chưa làm |
| M8 | Chiến đấu, quái, spawn, hầm đá, drop | Chưa làm |
| M9 | Chăn nuôi | Chưa làm |
| M10 | Nước, câu cá, thủy triều, bẫy | Chưa làm |
| M11 | Tri thức, câu hỏi, mini-game, phòng học | Chưa làm |
| M12 | Cốt truyện, 5 Bóng Quên, lễ hội | Chưa làm |
| M13 | Âm thanh, hiệu ứng, cân bằng, trợ năng, migration | Chưa làm |
| M14 | Thử nghiệm, sửa lỗi, đóng gói Windows | Chưa làm |

Skill cozy-school-pixel-art đã cập nhật theo GDD; profile riêng giữ quy chuẩn đồ họa, không thay thế lộ trình code. Không sinh art hàng loạt trước các mốc cần dùng.

Kiểm chứng M0: Godot 4.7.2 import/boot/test scene thành công; GUT 3/3 test, 22 assertions; ảnh render thật 1280×720 tại `docs/m0-pixel-grid.png`. M1 là mốc tiếp theo, chưa triển khai. Chưa đo hiệu năng map lớn vì chưa có map Godot.
