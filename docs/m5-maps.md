# M5 — Tương tác và chuyển map

GDD 5.2–5.5, 6.1–6.4. Boot quản lý một Player dùng chung, map cache tách khỏi SceneTree khi không dùng để không còn va chạm ẩn. SceneManager chuyển map với fade 0.25s mỗi chiều, giữ GameClock chạy, chặn input trong fade. Camera giới hạn theo kích thước map; map hiện không smoothing để ưu tiên pixel.

22 map/nội thất được khai báo trong data/balance/world.json. MapPortal là Area2D; InteractionDetector 20×20 nằm trước chân, chọn Interactable theo ưu tiên/gần nhất. E vào cổng có tên. Kiểm tra giờ cửa, ngày nghỉ, cờ mở khóa. NPC có ưu tiên cao hơn cổng. Nhà có giường E sau 20:00; lưu ô 1 khi ngủ. Các vị trí cổng và nội thất là bố cục kiểm thử, chưa đủ đồ đạc/nâng cấp/cutscene.

State map hiện lưu đất, hàng gửi, chests và flags; SceneManager lưu map hiện tại. Test xây toàn bộ 22 map và quay lại farm vẫn giữ cây. Chưa khẳng định hiệu năng của map hoàn thiện. Cảnh tests/scenes/test_m5.tscn.
