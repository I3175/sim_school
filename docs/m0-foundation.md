# M0 — Nền móng Godot

Phạm vi: GDD 0.2, 2, 3, 15.5. M0 chỉ dựng nền móng; chưa có gameplay.
Giả định: PC, tiếng Việt, Godot cài tại máy là 4.7.2; GUT 9.7.1 được ghim theo phiên bản này. GDD cho phép 4.3+, nhưng bộ test hiện yêu cầu 4.7.x. Nếu dùng engine cũ, chọn phiên bản GUT tương ứng.

## Chạy

Mở `project.godot` trong Godot, F6 tại `tests/scenes/test_m0.tscn` để kiểm tra ô 1 pixel và khung viền. F5 chạy boot trống như tiêu chí M0. Cửa sổ mặc định 1280×720, viewport logic 320×180; giữ tỉ lệ, scale nguyên, Nearest, snap transform/vertex. Đổi cửa sổ 1366×768 để kiểm tra viền đen thay vì kéo méo hình.

PowerShell: `./tools/test-godot.ps1 -Godot '<đường dẫn Godot console.exe>'`.

## API

`PixelScale.for_window(window_size, base_size = Vector2i(320, 180)) -> int`: scale nguyên tối thiểu 1, theo cạnh hạn chế. Engine tự áp dụng scale bằng Project Settings; helper phục vụ logic lựa chọn kích thước và kiểm thử. Các autoload ở mục 3.1 hiện chỉ đăng ký, chưa cung cấp API nghiệp vụ.

`tests/unit/test_pixel_scale.gd`: test scale chuẩn, cửa sổ không chia hết, trường hợp nhỏ/không hợp lệ, boot và autoload. `tests/scenes/test_m0.tscn`: cảnh kiểm tra độc lập. CI chạy import, boot và GUT; cấu hình CI chỉ được xác minh thực thi trên máy sau khi chạy workflow từ xa.

Nguồn kỹ thuật: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html ; https://github.com/bitwes/Gut (MIT, giấy phép trong addons/gut/LICENSE.md).

Bản HTML/Canvas trong game/ và asset cũ được giữ để tham khảo; không tính các tính năng đó là đã port sang Godot.

## Kết quả kiểm tra local

Godot 4.7.2: import thành công; boot và cảnh test chạy headless không lỗi. GUT 9.7.1: 3/3 test, 22 assertions đạt. Đã render và xem ảnh `m0-pixel-grid.png` ở 1280×720. CI đã có cấu hình nhưng chưa chạy trên GitHub.
