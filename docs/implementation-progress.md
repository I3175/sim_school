# Tiến độ Làng Sao Mai

Đối chiếu GDD mục 15.5. Đây là bản phát triển, chưa đạt nghiệm thu M1–M14 đầy đủ. Các mốc sau M0 hiện có lõi và scene kiểm thử, không đồng nghĩa đã có toàn bộ nội dung/art.

| Mốc | Đã triển khai | Còn thiếu chính |
| --- | --- | --- |
| M0 | Godot 4.7.2, autoload, pixel grid, GUT, CI cấu hình | CI chưa chạy từ GitHub |
| M1 | Di chuyển, stamina, 7 lớp nhân vật, camera, farm tilemap/Y-sort | Sprite sản xuất, đủ trạng thái/animation công cụ |
| M2 | Đồng hồ, mùa, ngày, dự báo/thời tiết seeded, ánh sáng, ngủ/ngất 02:00 | VFX thời tiết, tileset mùa, thư NPC/tổng kết khi ngất |
| M3 | Item resource, túi 36 ô, hotbar, rương, kéo/split, giao dịch, 3 ô lưu | Đủ menu theo GDD, save mã hóa |
| M4 | 14 cây, gieo/tưới/tăng trưởng/héo/tái sinh, thùng bán | Công thức chất lượng chờ người dùng; UI phân bón, sản lượng đặc biệt, art cây |
| M5 | 22 map định nghĩa, cache/portal, giờ cửa, cờ khóa, giường | Bố trí map thật, nội thất/obstacle navigation, toàn bộ công trình |
| M6 | 12 NPC có lịch và hội thoại, giao tiếp/quà, shop Dì Năm | 4 NPC bổ sung dùng lịch đơn giản; shop còn lại, sở thích và hội thoại đầy đủ |
| M7 | 8 loại quest, journal, accept/progress/claim/pin/reward | Quest mẫu; đủ chuỗi chính/phụ, craft/deliver/choice rewards |
| M8 | 5 quái, combat/XP/loot, spawn giữ trạng thái, HP/poison | 40 tầng có thể đi, boss, đủ vũ khí/quái, animation/hitbox cuối |
| M9 | Gà/bò, tuổi/nhu cầu/sản phẩm, chất lượng theo bảng, xây/mua/feed UI | Các vật nuôi khác, đi lại, khám bệnh/sưởi, art |
| M10 | 14 cá có điều kiện, minigame câu, thủy triều, bẫy, bảo toàn khi túi đầy | Tile/shader nước, đi trên băng, đủ cần/độ khó |
| M11 | 254 câu mẫu, 7 dạng đáp án, Leitner/adaptive, lớp học/practice | Thẩm định giáo dục; History-Geo chủ yếu xếp năm, drag-sort còn dùng bấm |
| M12 | Điều kiện chương 0–7, save/validation, Sổ Tay C, lịch lễ hội, model hậu kết; Bóng Số Không chơi thử | Còn 4 Bóng Quên và trùm cuối, cutscene, mục tiêu chương 3–6, hoạt động lễ hội; boss đầu dùng art/thông số tạm |
| M13 | Chưa thực hiện | Audio, trợ năng, balance, migration, đo FPS |
| M14 | Chưa thực hiện | QA kín và bản Windows đã kiểm chứng |

## Kiểm chứng gần nhất

- GUT: 46/46 tests, 1410 assertions, không có lỗi script/parse trong log M12.
- Cốt truyện: kiểm tra khóa theo ngày, thứ tự, năm sau, giờ trận cuối, điều kiện mảnh sao, save hỏng, ngày lễ hội.
- Ngất 02:00 kiểm thử tích hợp trên Boot: sang ngày, về nhà, phạt Xu, hồi HP/stamina, autosave. Bóng Số Không kiểm thử pha né/đáp án/gợi ý; đã render thật giao diện. Chưa chơi trọn năm.
- Art nhân vật/quái/cây đang là hình giữ chỗ; không tuyên bố sprite sheet sản xuất đã nghiệm thu.
- Chất lượng nông sản giữ mức thường (0) chờ công thức người dùng; không dùng bảng xác suất tự đặt.

## Tiếp theo theo thứ tự

Hoàn thiện M12 bằng các trận Bóng Quên và nội dung chương/lễ hội; sau đó M13 và M14. Các thiếu sót ở mốc trước phải được hồi quy trước nghiệm thu cuối.
