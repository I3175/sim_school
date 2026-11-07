# M3 — Túi, hotbar, rương, save

GDD 7.8, 8.1–8.3, 15.3. ItemData là Resource .tres, tên tiếng Việt trong localization/items.csv. Các icon hiện là placeholder SVG 16×16. I/Tab mở 36 ô túi; 1–0,-,= và cuộn chuột chọn hotbar; E gần rương tại (680,480) mở 36 ô rương. Kéo để chuyển/gộp/đổi; Shift+kéo lấy một nửa. Xếp gộp và sắp theo ID. L1–L3 lưu, T1–T3 tải.

InventoryModel: add trả số lượng còn dư; move_to chuyển nguyên tử; remove không trừ khi thiếu; valid_snapshot kiểm tra trước restore. Khác chất lượng không gộp. InventoryManager quản lý kho theo persistent_id. SaveManager thu thập/validate/restore qua EventBus, SaveStore ghi file tạm rồi đổi tên và giữ .bak. Lưu JSON version 1 tại user://saves; bản lưu chưa mã hóa. Các thẻ menu nghiệp vụ khác bổ sung tại mốc tương ứng.

Kiểm thử GUT gồm túi đầy, giới hạn stack, chất lượng, tách/gộp/đổi, self-drop, khôi phục JSON lỗi không mất đồ, 3 ô save và backup; integration kiểm tra load khôi phục player/Xu và reject payload sai trước mutation. Cảnh riêng tests/scenes/test_m3.tscn.
