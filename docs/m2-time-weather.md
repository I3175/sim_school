# M2 — Thời gian, mùa, thời tiết

GDD 4.1–4.7. `CalendarModel` giữ phút tuyệt đối; 10 giây thực = 1 phút game. Ngày nông nghiệp tính từ 06:00, giữ nguyên ngày sau nửa đêm đến khi ngủ. 02:00 dừng và phát sự kiện ngất một lần. `GameClock.start_next_day` bỏ qua đến 06:00 hôm sau. Các lý do pause độc lập để đóng menu không bỏ pause hội thoại.

`WeatherModel.day(index)` tái lập theo seed; ngày 1–3 và lễ hội nắng; không lặp cùng thời tiết nặng liên tiếp; tối đa 3 đoạn/ngày. Forecast sử dụng RNG riêng, đúng xác suất 90%, sai sang loại gần kề. Bảng mùa, xác suất, cờ đặc biệt nằm trong JSON. `WeatherSystem` phát trạng thái độ ướt/tuyết và dự báo qua EventBus. `day_lighting.gd` nội suy màu theo mùa/giờ bằng CanvasModulate.

F6 tests/scenes/test_m2.tscn. Dev F8 +1 giờ game, F9 ngủ; P tạm dừng. Phím dev không chạy trên export release. Hình phạt ngất, tác động quái/NPC/cây, thay bộ tileset mùa và hạt thời tiết cần tích hợp cùng các mốc tương ứng; chưa coi phần hình ảnh mùa hoàn thiện.

GUT kiểm tra chuyển đổi thời gian, ngất một lần, nested pause, năm/mùa, snapshot và 112 ngày thời tiết tái lập. Các thông số trong data/balance/calendar.json và data/weather/rules.json.
