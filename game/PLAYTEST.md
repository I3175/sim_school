# Bản thử desktop — School & Sprout

## Mở game

Nhấp đúp `RUN_GAME.cmd` ở thư mục gốc (cần Python 3), hoặc chạy:

```powershell
python -m http.server 8937 --bind 127.0.0.1
```

Sau đó mở http://127.0.0.1:8937. Dừng máy chủ bằng Ctrl+C. Nếu cổng đã được dùng, mở URL trước để kiểm tra hoặc dùng một cổng khác. Mở trực tiếp index.html cũng tải được game, nhưng một số trình duyệt chặn đọc pixel từ ảnh file:// nên sprite có thể còn khoảng đệm; HTTP là cách khuyến nghị.

## Cấu hình mùa trong code

Sửa `season` trong `game/config.js`, lưu rồi tải lại trang:

```js
season: 'spring', // spring, summer, autumn, winter
```

Mùa thay đổi nền cỏ/đường, màu cây, particle (cánh hoa/nắng/lá/tuyết), màu nước mùa đông, tên cây, thời gian lớn và giá bán. Mùa không tự luân phiên theo ngày; save không ghi đè cấu hình mùa. Các prop PNG chưa có sprite riêng cho từng mùa nên màu mái/nội thất giữ nguyên.

`cropGrowthSeconds` mặc định 18 giây để test nhanh; summer ×0.85, autumn ×1.1, winter ×1.25. `dayLengthSeconds` mặc định 720 giây. Chỉ thời gian đang chơi tiến triển; tạm dừng, mở hội thoại hoặc ẩn tab sẽ dừng cây và đồng hồ. Không tính thời gian ngoại tuyến.

## Điều khiển

- WASD hoặc phím mũi tên: đi. Shift: chạy.
- E: tương tác với điểm gần nhất; gợi ý hiện ở dưới khung game.
- 1 chọn bàn tay, 2 chọn hạt giống, 3 chọn bình tưới và 4 chọn cần câu.
- J mở nhật ký, bản đồ nhỏ và nút chuyển khu vực. Cây và đồng hồ dừng khi nhật ký mở.
- M bật/tắt bản đồ nhỏ trực tiếp trên màn chơi; K lưu nhanh. Thẻ mục tiêu hiển thị việc chưa hoàn thành tiếp theo và mở nhật ký khi nhấn.
- Esc đóng nhật ký hoặc hộp thoại. Khi đang ở map, Esc tạm dừng hoặc tiếp tục.
- Chuyển map trong nhật ký hoặc tương tác xe đưa đón.
- Nút ? mở hướng dẫn; ♪ bật/tắt hiệu ứng âm thanh; ⛶ toàn màn hình khung game.

## Vòng test chính

1. Trường: nhấn E trước tòa chính, vào cửa lớp từ hành lang rồi nhấn E tại bàn giáo viên để trả lời câu hỏi.
2. Ra sân bằng thảm trước cửa, vào thư viện và nhấn E tại bàn đọc sách.
3. Đến farm, đi sát một luống trống, 2 rồi E để gieo.
4. 3 rồi E để tưới. Đợi cây chín (chỉ cây có nước mới lớn).
5. E để thu hoạch; mỗi luống cho 1 nông sản.
6. Đến quầy nông sản, E và bán. Nhật ký đủ 6/6.

Mua 5 hạt với 10 xu tại quầy. Bón phân dùng 5 xu để tăng 8 giây sinh trưởng cho cây đã tưới. Thu mật ong 1 lần/ngày. Chế biến 2 nông sản tại bếp mứt/máy ép. Đọc sổ tay nhà kính, chọn bình tưới ở thùng nước.

Đi về phía đông tới hồ dưới thác. Chọn cần câu bằng phím 4 và nhấn E tại một trong hai bến. Mỗi lượt dùng 1 mồi. Khi vạch vào vùng xanh, nhấn E để giật cần. Có ba loại cá. Mua 5 mồi với 8 xu và bán cá tại quầy nông sản. Mồi và cá trong túi được lưu cùng tiến độ.

Vùng phía nam có đồng cỏ rào gỗ, vườn táo, anh đào và cam. Đi qua cổng mở để vào khu nuôi. Nhấn E gần vật nuôi để vuốt ve hoặc gần NPC để trò chuyện.

Ở trường còn có minigame bắt nhịp tại gym, bữa trưa tại căn tin, hiệu ứng màu tại phòng nghệ thuật, hoạt cảnh sân chơi và nghỉ sang ngày mới ở ghế đá. Học, đọc, gym, ăn trưa có giới hạn một lần/ngày.

## Lưu dữ liệu

Game tự lưu mỗi 10 giây, khi chuyển cảnh và sau tương tác. Nút lưu thủ công nằm trong nhật ký. Khóa `school-sprout-desktop-v1` lưu xu, kiến thức, hạt, nông sản, luống, nhiệm vụ, ngày và vị trí. Khi mở save cũ, nhân vật xuất hiện ở điểm bắt đầu của khu đã lưu. Khi mở lại một save tạo trong phòng, nhân vật đứng trước cửa công trình.

## Hình ảnh và animation

Dùng các atlas farm-workshop, School-Life-RPG đợt 1 và 2 đã tạo; nhân vật dùng spritesheet trong assets/characters có idle/walk/run và tư thế tương tác. NPC đi qua lại, cây/cầu treo đung đưa nhẹ, nước gợn, ong bay, hơi bếp, particle mùa và hiệu ứng gieo/tưới/thu hoạch được animate bằng code. Không phải tất cả props có animation vẽ từng frame.

## Phạm vi

Trường Bình Minh rộng 144 × 104 ô và farm rộng 164 × 112 ô, với 16 px mỗi ô. Dữ liệu trong `scenes.js` bố trí hai map ngoài trời và 14 phòng đi lại được. Nhấn E trước cửa để vào phòng hoặc trên thảm lối ra để quay lại. Một số phòng dành cho khám phá, còn các hoạt động có thưởng nằm ở bàn giáo viên, bàn đọc, sân tập và quầy ăn. Nông sản và nguyên liệu chế biến được quy đổi chung theo mùa.

Bộ Mầm Xanh trong `assets/mam-xanh` có địa hình 16×16, thác 6 frame, bọt 4 frame và cây theo mùa. Có thể tái xuất PNG bằng `python game/draw-mam-xanh.py` với Pillow. Hai bến có phần ván đi được.

Trường có 20 NPC, farm có 12 NPC. Mỗi người có điểm gặp riêng và hai câu thoại luân phiên. Nhấn E gần NPC để trò chuyện và xem chân dung. Xem [cấu trúc thư mục asset nhân vật](../assets/characters/README.md).

Bụi cây, hoa và đá trang trí dùng [Cozy Farm Lite của Bramble & Byte](https://opengameart.org/content/cozy-farm-lite-16x16-top-down-farm-tiles-crops-farmer-hen) theo [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), với kích thước được điều chỉnh khi vẽ. Vật nuôi và dụng cụ câu cá dùng [Farm & Ranch Life của Michel Clauwaert](https://michelclauwaertgmailcom.itch.io/farm-ranch-life-free-16x16-top-down-pixel-art-asset-pack). Xem [danh mục và giấy phép](../assets/farm-reference/README.md).

## Kiểm thử

`node game/test-core.cjs`: vòng cây trồng, kinh tế, thưởng nhiệm vụ một lần, tốc độ đi chéo, va chạm chống xuyên và phục hồi save.

`node game/test-browser.cjs` dùng Playwright và Chrome với máy chủ cổng 8937. Có thể đổi đường dẫn thư viện qua `PLAYWRIGHT_PATH`. Kiểm tra độ phủ sprite, khả năng tiếp cận điểm tương tác, vào ra 14 phòng, 6 nhiệm vụ, chuyển khu, lưu tiến độ, bốn mùa và hai kích thước cửa sổ. Các bài kiểm tra tương tác dùng phím E tại vị trí đã kiểm tra va chạm. Bài kiểm tra đường đi tìm đường từ điểm xuất phát riêng.
