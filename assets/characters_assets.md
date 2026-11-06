## Nguyên tắc thiết kế nhân vật pixel art 16 bytes

Với giới hạn 16×16 pixel, mỗi nhân vật chỉ có khoảng 256 pixel để thể hiện toàn bộ đặc điểm. Điều này đòi hỏi bạn phải tối ưu hóa từng pixel để tạo sự khác biệt rõ ràng giữa các nhân vật. Các yếu tố chính cần phân biệt bao gồm: **màu tóc**, **màu da**, **trang phục**, **phụ kiện** và **hình dáng tổng thể**.

## Bộ nhân vật

### Nhóm học sinh

| Tên | Vai trò | Phong cách pixel | Tính cách |
| --- | --- | --- | --- |
| **Mai** | Học sinh chăm chỉ | Tóc dài đen, áo trắng, váy xanh | Cần cù, tỉ mỉ, luôn ghi chép mọi thứ |
| **Sơn** | Học sinh năng động | Tóc vàng ngắn, áo đỏ, quần jean | Hiếu động, thích thể thao, hơi bốc đồng |
| **Lan** | Học sinh nghệ thuật | Tóc tím ngắn, áo họa tiết, khăn quàng | Sáng tạo, mơ mộng, hay vẽ vời |
| **Hùng** | Học sinh thích công nghệ | Tóc đen vuốt ngược, áo xanh dương, kính | Thông minh, hơi khép kín, mê máy móc |
| **Trang** | Học sinh thân thiện | Tóc nâu búi, áo hồng, nơ cài đầu | Hòa đồng, hay giúp đỡ bạn bè |

### Nhóm giáo viên và nhân viên nông trại

| Tên | Vai trò | Phong cách pixel | Tính cách |
| --- | --- | --- | --- |
| **Thầy Bình** | Giáo viên chủ nhiệm | Tóc muối tiêu, áo sơ mi trắng, kính gọng đen | Nghiêm khắc nhưng tận tâm |
| **Cô Hoa** | Giáo viên sinh học | Tóc dài búi, áo dài xanh, cầm sách | Dịu dàng, yêu thiên nhiên |
| **Bác Năm** | Quản lý nông trại | Tóc bạc, áo bà ba, nón lá | Kinh nghiệm, hiền lành, hay kể chuyện |
| **Chú Tư** | Kỹ thuật viên | Tóc đen, áo công nhân, mũ bảo hộ | Vui tính, khéo tay, thích sửa chữa |

## Mẹo tạo sự khác biệt trong 16 pixel

**Màu sắc chủ đạo**: Mỗi nhân vật nên có một màu chủ đạo riêng (đỏ, xanh, tím, vàng...) để người chơi dễ nhận diện từ xa. Ví dụ, Sơn luôn có áo đỏ, còn Lan luôn có khăn quàng tím.

**Hình dáng đầu**: Thay đổi kiểu tóc là cách hiệu quả nhất để phân biệt nhân vật trong pixel art nhỏ. Tóc dài, tóc ngắn, tóc búi, tóc vuốt ngược đều tạo silhouette khác nhau.

**Phụ kiện đặc trưng**: Kính, nón lá, nơ cài, khăn quàng là những chi tiết nhỏ nhưng tạo dấu ấn riêng. Trong 16×16 pixel, bạn có thể dành 2-3 pixel cho phụ kiện này.

**Bảng màu da**: Đa dạng hóa màu da (trắng, ngăm, nâu nhạt) giúp tăng tính đại diện và dễ phân biệt nhân vật.

## Gợi ý triển khai kỹ thuật

Khi tạo sprite sheet cho các nhân vật này, bạn nên thiết lập **bảng màu riêng cho từng nhân vật** (tối đa 8-12 màu mỗi nhân vật) để giữ tính nhất quán. Các animation cơ bản cần có: đứng yên, đi bộ, chạy, làm việc (tưới cây, thu hoạch), học tập (ngồi bàn, viết). Với 16×16 pixel, bạn có thể tạo 4-6 frame cho mỗi animation để đạt độ mượt vừa phải mà không tốn quá nhiều dung lượng.

---

## Phương án mở rộng cho School & Sprout

Danh sách dưới đây phát triển từ các mẫu ở trên và đối chiếu với các cảnh đang có trong game. Mục tiêu là **32 NPC có vai trò và tạo hình riêng**, gồm **20 người ở Trường Bình Minh** và **12 người ở Mầm Xanh**. Mỗi NPC có một điểm gặp chính. Sân trường, phòng học, các phòng chức năng, khu xe đưa đón và các điểm hoạt động chính ở farm đều có người phụ trách. Khu vệ sinh, nhà xe đạp và kho là điểm phụ do nhân vật gần đó chỉ dẫn.

### Vấn đề cần xử lý

- Hiện Cô Mai xuất hiện ở cả sân lẫn tòa chính, còn An xuất hiện ở sân lẫn thư viện. Khi làm dàn mới, **Mai** là học sinh, **Cô Thu** phụ trách sảnh và **An** chỉ xuất hiện trong thư viện. Thầy Bình phụ trách tiết học. Cập nhật lời dẫn cũ để khớp người và địa điểm.
- NPC farm hiện dùng nhiều nét mặt, thân và tư thế chung. Chân dung được phóng từ sprite nên thiếu biểu cảm và chi tiết nghề nghiệp. Bản mới cần vẽ dáng riêng và chân dung riêng cho từng người, cùng một hệ ánh sáng và nét viền.
- **Sơn** là học sinh thể thao. Nhân vật chủ đồng cỏ đang mang tên Chú Sơn đổi tên hiển thị thành **Chú Cường**, giữ ID `rancher`. **Bác Tư** vẫn là người câu cá. Mẫu kỹ thuật viên **Chú Tư** đổi tên hiển thị thành **Chú Kiên**. **Bác Năm** là quản lý nhà kính, có áo bà ba và khăn rằn thay cho nón lá để nhận diện khác Bác Tư.

### 20 NPC Trường Bình Minh

| Tên · ID | Điểm gặp và vai trò | Dấu hiệu đọc được trên map | Hướng thoại |
| --- | --- | --- | --- |
| Mai · `school_mai` | Phòng học, học sinh chăm chỉ | Tóc đen dài thành một mảng sau vai, đồng phục trắng và váy xanh, sổ vàng ôm trước ngực | Ghi chép, ôn bài và nhắc tìm Thầy Bình |
| Sơn · `school_son` | Nhà thể chất, học sinh năng động | Tóc vàng ngắn dựng, áo đỏ, quần jean xanh sẫm, băng cổ tay và bóng cam | Rủ thử phản xạ, kể chuyện tập ném bóng |
| Lan · `school_lan` | Phòng nghệ thuật, học sinh vẽ | Tóc tím lệch một bên, khăn quàng có đuôi, sổ vẽ nhỏ | Nhận xét màu theo mùa và giới thiệu góc vẽ |
| Hùng · `school_hung` | Phòng thí nghiệm, học sinh mê công nghệ | Tóc đen vuốt ngược, áo xanh dương, kính chữ nhật và thiết bị cầm tay | Hỏi về thiết bị và nhắc quy tắc an toàn |
| Trang · `school_trang` | Sân chào cờ, học sinh hỗ trợ bạn mới | Tóc nâu búi thấp, nơ hồng một bên, túi đeo dọc | Chỉ bảng tin và lối sang khu xe |
| Thầy Bình · `school_binh` | Phòng học, giáo viên chủ nhiệm | Dáng cao đứng thẳng, tóc muối tiêu rẽ ngôi, sơ mi trắng, kính tối và giáo án gập | Dẫn vào tiết học bằng câu hỏi ngắn |
| Cô Hoa · `school_hoa` | Nhà kính trường, giáo viên sinh học | Tóc cuộn sau đầu, áo dài xanh lá có tà rõ, sách cây màu kem | Giải thích cách chăm cây theo mùa |
| Cô Thu · `school_thu` | Sảnh tòa chính, hành chính | Dáng vuông, tóc ngang vai rẽ giữa, áo ghi lê be và bảng kẹp hồ sơ | Chỉ cửa lớp, giải thích sơ đồ tòa nhà |
| Minh · `school_minh` | Sân chơi, học sinh thích vận động ngoài trời | Tóc xù ngắn, áo vàng mù tạt, quần lửng và dây nhảy cuộn | Giới thiệu sân chơi và nhắc nhường lượt |
| An · `school_an` | Thư viện, học sinh mê truyện | Tóc mái tròn, áo lam nhạt, chồng truyện hai màu cao gần cằm | Gợi ý một quyển sách và chỉ bàn đọc |
| Bác Lâm · `school_lam` | Cụm trạm bảo vệ, nhà xe và xe đưa đón | Dáng đậm, mũ kêpi xanh rêu, râu bạc và vòng chìa khóa | Chỉ xe sang farm và khu đỗ xe |
| Thầy Hải · `school_hai` | Phòng thí nghiệm, giáo viên phụ trách | Áo blouse trắng dài, tóc xoăn sát, kính bảo hộ đẩy lên đầu và ống nghiệm lam | Giải thích mô hình nguyên tử, nhắc dùng bồn rửa |
| Cô Diệp · `school_diep` | Thư viện, thủ thư | Tóc búi cao gọn, áo mận sẫm, kính dây mảnh và thẻ mượn sách | Hướng dẫn mượn sách và góc ngồi yên |
| Cô Nhung · `school_nhung` | Phòng nghệ thuật, giáo viên | Dáng thanh, tóc tém nâu đỏ, tạp dề loang màu và bảng pha màu | Gợi ý phối màu, chỉ nơi thử vẽ |
| Thầy Khải · `school_khai` | Nhà thể chất, giáo viên thể dục | Vai rộng, tóc sát, áo khoác xanh lá, còi và bảng điểm | Giới thiệu bài tập phản xạ |
| Chị Yến · `school_yen` | Căn tin, phụ trách bữa trưa | Mũ trùm vải trắng, tạp dề xanh ngọc và khay thức ăn ngang người | Báo món trong ngày và chỉ quầy mua |
| Anh Phúc · `school_phuc` | Hồ bơi, cứu hộ | Mũ bơi xanh đậm, áo cứu hộ cam sáng, phao tròn bên hông | Nhắc đứng ở thành hồ, chỉ khu tắm |
| Cô Hạnh · `school_hanh` | Phòng y tế, nhân viên y tế | Tóc đuôi ngựa thấp, áo khoác kem ngắn, túi sơ cứu đỏ nhỏ | Chỉ giường nghỉ và hỏi thăm sau khi tập |
| Cô Thảo · `school_thao` | Ký túc xá, quản lý tầng | Tóc đen điểm bạc, áo cardigan vàng nâu, chùm chìa khóa dài bên váy | Chỉ khu giặt và nhắc giữ yên tĩnh |
| Anh Quân · `school_quan` | Hội trường, phụ trách sân khấu | Tóc cắt sát hai bên, áo gile chàm, tai nghe một bên và cuộn dây | Chỉ sân khấu và kể về buổi diễn sắp tới |

### 12 NPC Nông trại Mầm Xanh

Mười người hiện có được chỉnh tạo hình. Bác Năm và Chú Kiên là hai vai bổ sung từ tài liệu mẫu. Giữ ID farm đang dùng để việc đổi sprite và tên hiển thị không ảnh hưởng các liên kết theo vai.

| Tên · ID | Điểm gặp và vai trò | Dấu hiệu đọc được trên map | Hướng thoại |
| --- | --- | --- | --- |
| Chú Nam · `nam` | Quầy nông sản, thu mua | Dáng đậm, khăn buộc trán ngang, tạp dề nâu và cân tay | Giá bán và phân loại nông sản |
| Chị Sen · `seed_seller` | Giá hạt gần quầy, bán hạt | Tóc bob ôm cằm, yếm tím mận, túi hạt đeo chéo | Chọn hạt và phân biệt đất khô với đất ướt |
| Bé Mận · `farmhand_kid` | Lối giữa nhà kính và ruộng, phụ chăm cây | Thấp nhất nhóm, hai chùm tóc tách rõ, áo cam và bình tưới xanh | Đếm mầm mới và chỉ chỗ lấy nước |
| Bác Năm · `farm_manager` | Nhà kính farm, quản lý | Dáng lớn tuổi hơi khom, tóc bạc, áo bà ba chàm và khăn rằn trên vai, sổ mùa vụ | Kể cách chọn cây theo mùa, chỉ bàn ươm |
| Cô Hương · `beekeeper` | Tổ ong, chăm ong | Tóc búi dưới mũ lưới, áo vàng mật, găng sáng và lọ mật | Chỉ cách nhận mật và kể về hoa dại |
| Chú Cường · `rancher` | Cổng đồng cỏ, chăm vật nuôi | Vai rộng, mũ rơm vành ngang, áo đỏ gạch và ủng | Chỉ lối vào khu nuôi, nhắc vuốt ve vật nuôi |
| Bà Sáu · `orchard_keeper` | Vườn cây phía nam, chăm vườn | Tóc bạc lộ ở thái dương, khăn trùm xanh lá và giỏ quả rộng | Kể chuyện cây nở hoa và mùa hái quả |
| Chú Kiên · `farm_mechanic` | Sân trước kho, kỹ thuật viên | Dáng tầm trung, mũ bảo hộ tròn màu vàng, áo công nhân xanh thép và cờ lê | Giới thiệu kho và cách vận hành máy ép |
| Cô Liên · `travelling_merchant` | Trạm xe phía tây, khách buôn | Dáng cao, bím tóc dài lệch một bên, áo chàm và giỏ đeo lưng | Kể chuyện đi lại và chỉ đường vào các khu |
| Anh Đạt · `carpenter` | Bến câu phía tây, thợ mộc | Đầu để trần, tóc cắt vuông, tay áo xắn và búa gỗ ở đai | Kể chuyện đóng bến và chỉ phần ván đi được |
| Bác Tư · `fisher` | Bến câu phía nam, người câu cá | Dáng gầy, nón lá hình tam giác, áo xanh sông và cần câu xiên | Hướng dẫn chọn cần, giật cần và mua mồi |
| Chị Vân · `naturalist` | Đường ngắm thác, quan sát thiên nhiên | Tóc xoăn gọn, kính tròn, áo xám xanh và sổ tay mở | Chỉ đường lên điểm ngắm và kể về cây ven hồ |

### Quy chuẩn tạo hình và animation

1. **Giữ lưới map 16×16 px, dùng ô sprite nhân vật 32×32 px.** 16×16 trong tài liệu là kích thước ô địa hình. Khung nhân vật 32×32 cho phép dùng chung trình vẽ NPC hiện có và chừa chỗ cho tóc, tà áo, nón và phụ kiện. Neo bàn chân giữa đáy khung. Có ba nhóm chiều cao và ít nhất ba kiểu bề ngang thân, giữ lối đi và điểm tương tác theo chân.
2. **Chốt silhouette trước khi tô màu.** Mỗi người khác người gần mình ở ít nhất hai đặc điểm trong các nhóm chiều cao/dáng, tóc/mũ, đường viền trang phục và đạo cụ. Kiểm tra hình đen ở cỡ chơi thật. Sau đó dùng bảng màu chung cho ánh sáng, bóng và viền. Mỗi vai dùng 8–12 màu chính, có tông da và tông tóc đa dạng. Đồng phục trường dùng dấu hiệu chung nhỏ để học sinh vẫn thuộc cùng một trường.
3. **Vẽ riêng đầu và thân theo hướng nhìn.** Mặt trước, lưng và hai bên phải thể hiện được kiểu tóc, chân và vị trí đạo cụ. Phụ kiện lệch vai giữ đúng bên qua các hướng. Vẽ mắt và miệng tối giản, tách tóc khỏi màu da bằng mảng sáng/tối rõ. Tránh tạo danh sách bằng cách thay mã màu trên cùng một khuôn mặt.
4. **Một chân dung riêng 64×64 cho mỗi NPC.** Vẽ bán thân ở góc 3/4, biểu cảm theo tính cách, có cùng kiểu tóc, tông da, trang phục và đạo cụ với sprite. Dùng khung hội thoại gỗ của game. Chân dung cần có chi tiết riêng ở mắt, tay hoặc chất liệu áo để đọc rõ khi mở hội thoại.
5. **Chuẩn hóa sheet 192×128 px.** Bốn hàng lần lượt xuống, lên, phải, trái. Mỗi hàng có 4 frame đi rồi 2 frame đứng. Chạy animation đi khoảng 7–8 fps, đứng 2 fps. Giữ chân neo ổn định và dùng nearest-neighbor. Sau đợt nền, bổ sung động tác gắn với vai ở các điểm dùng thật, như Mai viết, Lan vẽ, Bé Mận tưới, Bác Tư thả câu. Nhân vật người chơi giữ sheet riêng cho các động tác chạy và tương tác hiện có.

### Tích hợp và kiểm tra

- **Dữ liệu NPC.** Một danh mục dùng ID ổn định, tên hiển thị, cảnh chính, tọa độ neo, tuyến đi ngắn, đường dẫn sheet/chân dung và hai câu thoại. Mỗi ID chỉ được đặt một lần trong dữ liệu cảnh. NPC dừng và quay mặt về người chơi khi nói chuyện, tiếp tục đi khi đóng thoại. Giữ khung game và luồng nhiệm vụ hiện tại. NPC mới dẫn tới hoạt động qua lời thoại, còn phần thưởng tiếp tục xử lý ở điểm học, đọc, tập, mua bán hoặc câu cá hiện có.
- **Đợt 1 — duyệt 4 mẫu.** Làm Mai, Thầy Bình, Bé Mận và Bác Tư, gồm sprite đủ hướng, chân dung và ảnh đặt trong game. So bản thang xám ở cỡ thật để phân biệt bốn dáng, rồi đối chiếu màu ở cả sân trường và farm. Chốt tỷ lệ, nét viền, độ nổi mặt và chiều cao trước khi vẽ tiếp.
- **Đợt 2 — dựng theo cụm.** Hoàn thiện trường theo luồng sảnh → lớp → phòng chức năng → khu xe. Sau đó hoàn thiện farm theo luồng trạm xe → quầy → ruộng/nhà kính → đồng cỏ/vườn → hồ. Kiểm tra ảnh nhiều NPC đứng cạnh nhau sau mỗi cụm và sửa cặp dễ nhầm trước khi chuyển sang cụm kế.
- **Nghiệm thu.** Đủ 32 ID, 32 sheet và 32 chân dung riêng. Kiểm tra các cặp đứng chung cảnh ở **1280×800** và **1920×1080**, với và không có nhãn tên. Mỗi NPC đúng hướng khi đi và dừng, có thể tiếp cận để nói chuyện và hiển thị đúng hai câu thoại. Tuyến NPC không đi vào nước, tường hoặc chắn cửa. Chạy lại vòng 6 nhiệm vụ, vào/ra phòng, đổi khu và tải save.
