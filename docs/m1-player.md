# M1 — Player và nông trại mẫu

GDD: 2, 5.2, 7.2–7.3, 7.5, 7.7, 15.1. F5 chạy nông trại; F6 tại tests/scenes/test_m1.tscn chạy riêng. WASD/mũi tên/cần trái di chuyển; Shift chạy. Tốc độ 64/96 px/s, chéo chuẩn hóa, chạy tốn 0.5 thể lực/s.

VillagePlayer.movement_velocity là logic thuần. snapshot()/restore() giữ vị trí, hướng và thể lực; lưu file được ghép ở M3. AnimationPlayer điều khiển frame chung của 7 lớp; idle 2 khung/2 FPS, walk 6/10, run 6/14, hàng xuống/lên/trái, phải lật trái.

Ground là TileMapLayer, Entities bật Y-sort, điểm gốc vật thể ở chân. Farm 80×60 ô. Va chạm chỉ chân cây/nhà và biên map. Tileset Tiny Town của Kenney CC0, giấy phép gốc tại assets/topdown-16x16/tiny-town/License.txt. Nhân vật SVG là đồ họa kiểm thử tự viết, không phải asset cuối; manifest ghi rõ kích thước và frame. Đây chưa phải bố cục nông trại hoàn thiện.

GUT: tốc độ chéo, đồng bộ frame/hướng, snapshot qua JSON, tiêu hao/hồi thể lực, va chạm cây, tilemap và camera. Tổng M0+M1: 7 test, 54 assertions đạt.

API: https://docs.godotengine.org/en/4.4/classes/class_tilemaplayer.html
