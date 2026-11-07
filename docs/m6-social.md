# M6 — NPC, hội thoại, cửa hàng

GDD 8.3, 9.7, 5.5. Dialogue Manager v4.2.0 (MIT) từ https://github.com/nathanhoad/godot_dialogue_manager ; dùng get_next_dialogue_line với UI riêng phù hợp viewport 320×180. Plugin lưu nguyên LICENSE trong addons/dialogue_manager. Nội dung .dialogue.txt được compile runtime. Dự án hiện dùng Godot 4.7.2; plugin này yêu cầu 4.6+.

8 NPC ban đầu, lịch JSON weekday/weekend/rain/festival. NavigationAgent2D di chuyển trên vùng điều hướng; geometry vùng hiện là hình chữ nhật, chưa bake tránh tất cả props. Model chuyển địa điểm theo lịch; NPC chỉ được tạo ở map đang xem. Hội thoại đổi theo mưa hoặc 2 tim; nói chuyện +20/ngày, một quà/ngày. Sở thích riêng chưa có dữ liệu nên quà đang neutral (+20). Chưa có 12 bộ sprite/chân dung hay sự kiện tim.

Tiệm Dì Năm: mua hạt theo mùa, bán vật đang chọn, kiểm tra giờ mở cửa. Transaction inventory và Xu nguyên tử. Các shop khác và dịch vụ nâng cấp vẫn chưa có UI. NPC/UI art còn placeholder. F6 tests/scenes/test_m6.tscn; đi phố chợ/trong tiệm đúng giờ, E nói chuyện.

Test lịch mưa, lễ hội, giới hạn điểm/ngày, parse/nhánh Dialogue Manager, mua khi túi đầy không mất tiền. M6 hiện là luồng chức năng ban đầu, chưa hoàn thiện toàn bộ nội dung GDD.
