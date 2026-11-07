# M4 — Nông nghiệp

GDD 5.3, 7.5, 8.1, 12.1–12.3. Vùng 24×16 ô bắt đầu tại (28,34). Đứng cạnh ô, nhìn vào ô và nhấn J/click: cuốc (hotbar 1), tưới (2), gieo hạt (3). E thu hoạch. Chọn nông sản, E gần hòm gửi hàng tại (712,480); nhận tiền sáng sau. Dev F9 qua ngày để kiểm thử nhanh.

14 CropData .tres theo bảng GDD, cùng ItemData hạt/nông sản. FarmingModel giữ đất, tuổi cây, chuỗi ngày khô/tưới, héo, phân bón, mùa và thu lại. Mưa tưới tự động; nắng nóng làm khô lúc 12:00. Callback ngày có idempotency; tải save không phát day_started. Harvest chỉ xóa cây sau khi transaction thêm đồ thành công. Shipping trừ đúng chất lượng, tính tiền sau ngày và lưu cùng map.

Core hỗ trợ phân chất lượng/tăng trưởng/giữ nước; chưa có đồ phân bón trong luồng shop. Người dùng sẽ cung cấp công thức chất lượng. Đã bỏ bảng xác suất tạm; harvest hiện trả chất lượng thường, phần này chưa hoàn thành. Cây/đồ hiển thị còn placeholder; chưa có hiệu ứng gió, sét hoặc biến thể khoai tây 1–2 củ. Không coi toàn bộ nội dung nông nghiệp đã hoàn thiện.

Test: cây tăng khi tưới, khô 3 ngày héo, đúng mùa, greenhouse, thu lại, JSON roundtrip; test tích hợp trồng–thu–gửi–nhận Xu 3 ngày, tải không nhận tiền thêm. tests/scenes/test_m4.tscn chạy độc lập.
