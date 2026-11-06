# School Life RPG — tiến độ theo school_asset.md

Nguồn yêu cầu: `../cozy-farm-school/school_asset.md`. Ngày bắt đầu: 06/11/2026. Người dùng chọn thực hiện toàn bộ theo từng đợt. Không sửa danh sách nguồn.

## Quy ước trạng thái

- Có ảnh: đã sinh atlas, chưa đồng nghĩa đã đạt pixel art native 16×16/32×32.
- Sẵn sàng kỹ thuật: cần kiểm tra từng sprite, chuẩn hóa pixel, anchor, collision và các hướng nhìn.
- Animation hoàn thiện: cần đúng số frame, động tác, hướng nhìn, loop và khả năng ghép layer; ảnh một tư thế không được tính là animation.

## Các đợt

| Đợt | Nội dung | Trạng thái |
| --- | --- | --- |
| 1 | 64 đồ vật: lớp học; thư viện–lab–art–gym; căn tin–hành lang; khuôn viên | Đã tạo 4 atlas PNG, metadata 64 ô và trang xem trước; còn bước chuẩn hóa pixel |
| 2 | Công trình theo school_building.md, nội thất bổ sung, CLB và đồ sự kiện | Đã tạo 16 ngoại thất + 16 đồ vật nội thất trong Batch-02; các mục còn lại chưa tạo |
| 3 | 10+ học sinh premade, giáo viên nam/nữ, hiệu trưởng, giáo viên thể dục/nghệ thuật; các layer modular tóc/mắt/da/quần áo/phụ kiện | Chưa tạo |
| 4 | Toàn bộ animation cơ bản và hoạt động theo đúng số frame trong nguồn | Chưa tạo |
| 5 | Đồ học tập, đồ cá nhân, vật phẩm đặc biệt, đồ ăn còn thiếu, 100+ icon, UI | Chưa tạo |
| 6 | Chó, mèo, chim, sóc, cá; thời tiết, lá rơi, hoa nở, bóng cây, ánh đèn và particle | Chưa tạo |
| 7 | Chuẩn hóa native 16×16/32×32, pixel density, spritesheet, metadata, kiểm tra tích hợp | Chưa hoàn thiện |

## Phần còn thiếu sau đợt 1

- Thư viện: thẻ thư viện, sách nhiều màu tách thành vật phẩm riêng.
- Lab: bình hóa chất, bảng tuần hoàn, kính bảo hộ.
- Art: khung tranh, cọ riêng, đất sét riêng. Bàn xoay gốm trong đợt 1 là bổ sung.
- Gym: bóng rổ, bóng đá, bóng chuyền tách riêng.
- Biến thể bàn ghế, bảng thông báo hành lang, các hướng nhìn và trạng thái cửa/locker.
- Căn tin: mì, bánh ngọt, kẹo và các biến thể đồ ăn/uống riêng.
- Đường đi, cỏ và sân bóng đợt 1 là mảng minh họa tĩnh; chưa phải terrain nối liền/autotile.
- Mọi nội dung nhân vật, modular, animation, vật phẩm, CLB/sự kiện, động vật, hiệu ứng và 100+ icon vẫn cần các đợt tiếp theo.

## Tiêu chuẩn cần giữ

## Bổ sung theo school_building.md (06/11/2026)

Nguồn mở rộng: `../school_building.md`. Đợt 2 lưu ở `Batch-02/`; xem `Batch-02/preview.html`. Tổng hiện có 96 mẫu tĩnh trong 6 atlas, chưa phải 96 sprite đã chuẩn hóa pixel.

- Đã có ngoại thất: tòa chính, thư viện, lab, art, gym, căn tin, hồ bơi, ký túc xá, hội trường, y tế, vệ sinh, nhà xe đạp, kho, bảo vệ, trạm xe buýt, nhà kính.
- Đã bổ sung nội thất: lễ tân, bàn hiệu trưởng, ghế xoay, tủ hồ sơ, máy in, két sắt, giường y tế, tủ thuốc, bàn họp, máy pha cà phê, giường tầng, máy giặt, buồng tắm, ghế cứu hộ, sân khấu, bục phát biểu.
- Đã lưu thông số kích thước 11 khu vực vào `Batch-02/layout-specs.json`; chưa dựng map.
- Còn thiếu: các phòng bố trí đầy đủ, nội thất chi tiết trong tài liệu, đài phun nước, tượng đài, bảng LED, khu đỗ xe hoàn chỉnh, chi tiết vườn, vật liệu tường/mái/nền và hệ thống ghép tile. Các nhóm nhân vật/animation/icon/hiệu ứng và CLB vẫn chưa tạo.

PNG có alpha, phong cách cozy tươi sáng, góc nhìn RPG từ trên xuống. Các atlas do ImageGen tạo hiện là ảnh độ phân giải cao mang phong cách pixel art; không tự coi là sprite native 16×16 hoặc bộ game hoàn chỉnh. Từng giai đoạn cần cập nhật trạng thái thực tế.
