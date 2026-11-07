# M12 — nền tảng cốt truyện

Trạng thái: **chưa hoàn tất M12**. Đã có Bóng Số Không chơi thử; còn 4 Bóng Quên, Kẻ Xóa Chữ, cutscene và hoạt động lễ hội. `StoryModel` định nghĩa điều kiện và lưu tiến độ; `complete_boss` được gọi sau khi thắng encounter, không có nút nhận mảnh miễn phí.

## Đã nối vào game

- Nhấn **C** xem Sổ Tay, Esc/C đóng. Scroll danh sách mục tiêu; mở sổ tạm dừng thế giới. Scene `tests/scenes/test_m12.tscn` mở sẵn sổ.
- Chương mở đầu nhận sự kiện đến nông trại, cuốc, gieo thành công (sau giao dịch hạt giống), gặp Dì Năm, sang ngày sau khi ngủ.
- Chương 1 nhận gặp đủ 12 NPC, thu hoạch và đến trường. Quest mẫu thu hoạch không còn tự cấp cờ `chapter_1`.
- Bổ sung Ông Sáu, Bé Na, Anh Khoa, Marco; giữ ID `thu_thu` tương thích dữ liệu cũ và đổi tên hiển thị thành Bà Tư. Bốn NPC mới có lịch/hội thoại tối thiểu, chưa phải nội dung hoàn chỉnh theo nghề.
- Ngày mở chương dùng chỉ số tuyệt đối 0, 1, 3, 7, 11, 14, 18, 21; phải xong chương trước. Không reset vào năm mới.
- `StoryManager` lưu `state.story`, kiểm tra dữ liệu trước load; save cũ thiếu mục này khởi đầu lại phần truyện. Các cờ map đã có trong save cũ không bị thu hồi tự động.
- Rừng cần xong chương 1; mỏ thêm Cư Dân 3; núi thêm xong chương 5/Cư Dân 8. Cầu không tự mở theo chương, chờ mục tiêu sửa cầu.
- Năm mảnh có thứ tự; không nhận mảnh lặp. Trận cuối chỉ đủ điều kiện Đông 7, 20:00–trước 23:00, có thể đợi năm sau.
- Lịch lễ hội đúng ngày 7 và 10:00–trước 23:00. Đây mới là lịch và thông báo, chưa có gian hàng/minigame.

## Quy tắc tạm cần chốt nội dung

GDD chưa nêu điểm đo “phát triển Trường/Thư viện/Nông trại”. Model hiện đếm sao học Toán/Anh/Khoa học cho Trường, Văn/Sử-Địa cho Thư viện, số lần thu hoạch cho Nông trại. Nếu bằng điểm, Nông trại ưu tiên. Đây là quy tắc phát triển thử nghiệm, cần thay bằng nâng cấp công trình trước nghiệm thu hậu kết.

## Phần còn lại trước M13

1. Mục tiêu và cutscene riêng của chương 2–7: Chìa Mực, phục hồi sách, sửa cầu, Marco, cơ khí, di tích, lắp mảnh.
2. Hoàn thiện art/cân bằng Bóng Số Không; xây 4 Bóng Quên còn lại và Kẻ Xóa Chữ; không dùng kết quả học thường thay thắng boss.
3. Dash, hầm sách, các tầng mỏ, áo phao/nhà kính và mở khóa khác.
4. Trang trí và hoạt động cả bốn lễ hội; hậu kết có trình bày trong game.
5. Kiểm thử chơi trọn năm qua input thật, không chỉ model.

## Kiểm chứng

GUT `test_story.gd`: chương/ngày, dữ liệu qua JSON, tiếp tục năm sau, mảnh một lần, cửa sổ trận cuối, hậu kết, lễ hội và save hỏng. Tổng suite hiện 46 tests/1410 assertions. Render thật: `docs/m12-story-journal.png`; không có script error trong log render.

## Bóng Số Không — bản chơi thử

Trong chương 2, vào Trường, tương tác **E · Hầm trường**. WASD/mũi tên né vùng vàng trước khi số 0 rơi. Sau mỗi pha né, đến gần đáp án rồi **J**; ba lần đúng nhận Mảnh Số và hoàn thành chương 2. Sai ba lần ở cùng câu hiện đáp án gợi ý, người chơi vẫn cần tiếp cận và đánh. Esc rút lui, không nhận mảnh; quay lại bắt đầu trận từ đầu. HP dùng HP thật của nhân vật; ngất đóng đấu trường và áp dụng xử lý ngất chiến đấu.

`ZeroEncounterModel` giữ pha/hazards/câu hỏi; `ZeroEncounter` hiển thị và nhận input. `data/balance/zero_encounter.json` chứa thời gian/sát thương/câu hỏi tạm. Scene riêng `tests/scenes/test_m12_zero.tscn` đặt chương 2 và mở đấu trường để kiểm tra, **không phải chế độ chơi chính**.

Giới hạn: đấu trường hiện là overlay tạm dừng đồng hồ/thế giới; nhân vật, ô rơi và đáp án là đồ họa giữ chỗ. Chỉ ba câu Toán cố định, chưa nối ngân hàng câu thích ứng, animation vỡ boss/cutscene nhận mảnh hoặc kỹ năng dash. Chưa thể coi M12 đã nghiệm thu.

Ảnh `docs/m12-zero-encounter.png` render pha đáp án được đặt sẵn để kiểm tra bố cục. GUT kiểm tra pha né không bị bỏ qua bằng J, khoảng cách đánh, ba câu bắt buộc, cảnh báo rơi/né/không trúng lặp và gợi ý sau ba sai.

## Sửa vòng ngủ phục vụ chương mở đầu

Giường hỏi xác nhận; ngủ trước 24:00 hồi đủ HP/thể lực, sau 24:00 giảm 5% mỗi 10 phút tới mức 70%. Ngất 02:00 tự về nhà, sang ngày, mất 5% Xu tối đa 500, hồi 50% thể lực/75% HP, hết độc rồi autosave ô 1. Thư NPC và màn tổng kết riêng còn thiếu. Kiểm thử tích hợp dùng thư mục save tạm, không ghi đè save người chơi.
