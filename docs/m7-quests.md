# M7 — Nhiệm vụ

GDD 9.3, 9.5–9.6. 8 QuestData .tres đại diện 8 loại, nội dung mẫu để kiểm thử. Q mở nhật ký, Nhận để bắt đầu, Ghim tối đa 3, Lĩnh thưởng khi Ready. Prerequisite cờ/chuyến khám phá/hữu nghị/lễ hội; main không hết hạn, daily lặp theo cooldown. Hoàn thành thu hoạch đầu mở cờ chapter_1. Phần thưởng item/Xu qua transaction, chỉ claim một lần; XP Cư Dân lưu trên Player.

QuestModel hỗ trợ objective sự kiện tuần tự/song song và optional; QuestManager hiện nối harvest/talk/reach. Các event combat/fish/animal/puzzle cần nối ở mốc sau. Chưa có toàn bộ kênh giao nhiệm vụ, rating 2–3 sao, reward lựa chọn, đủ 4–8 quest mỗi chương hoặc tất cả loại objective. Không coi các quest mẫu là cốt truyện M12.

Test một nhiệm vụ mỗi loại từ Available tới Claimed, duplicate claim bị chặn, daily hết hạn/lặp và hidden prerequisite. Save chứa states/pinned/discovered. Cảnh tests/scenes/test_m7.tscn.
