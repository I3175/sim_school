# Làng Sao Mai — Game Design Document

*Phiên bản 1.0 · Godot 4.x · Pixel art 16-bit (tile 16×16) · Nông trại + RPG + Giải đố + Học tập*

### 0. Giả định đã chọn (có thể sửa)

| # | Giả định | Ghi chú |
| --- | --- | --- |
| 1 | «16bytes» hiểu là **pixel art 16-bit, tile 16×16** | Nhân vật 16×32, tile 16×16 |
| 2 | Godot **4.3+**, ngôn ngữ **GDScript** | C# có thể thay sau |
| 3 | **1 mùa = 7 ngày, 1 năm = 28 ngày** | Vì 1 ngày dài 240 phút nên mùa ngắn; 1 năm ≈ 93 giờ chơi. Chỉnh ở `GameConstants` |
| 4 | Single-player, PC trước, mobile sau | Input Map hỗ trợ bàn phím, chuột, tay cầm |
| 5 | Tiếng Việt là ngôn ngữ chính, i18n bằng CSV | Có thể thêm tiếng Anh |
| 6 | Không PvP, không phạt nặng | Thua trận chỉ mất ít Xu/đồ nhẹ |
| 7 | Học tập **không bao giờ chặn cốt truyện cứng** | Luôn có «Gợi ý», «Bỏ qua tạm» và chế độ ôn luyện |

---

## 1. Tầm nhìn sản phẩm

**Tagline:** *«Làm nông, khám phá, và thắp lại ngôi sao tri thức của ngôi làng.»*

### 1.1 Năm trụ cột thiết kế

1. **Thư thái:** nhịp chơi chậm, không áp lực thời gian thật; thất bại luôn có đường lui.
2. **Tri thức là sức mạnh:** học = mở khóa công thức, giảm giá, tăng chỉ số, mở khu vực. Không học vẫn chơi được nhưng chậm hơn.
3. **Thế giới sống:** thời gian, mùa, thời tiết, NPC có lịch sinh hoạt thật.
4. **Mỗi khu vực một bản sắc:** mỗi map có chủ đề, nhạc, bảng màu, cơ chế riêng.
5. **Quyết định có ý nghĩa:** chọn trồng gì, nuôi gì, đánh hay câu, học môn nào đều ảnh hưởng tiến trình.

### 1.2 Vòng lặp chơi (core loop)

| Chu kỳ | Người chơi làm gì | Phần thưởng |
| --- | --- | --- |
| 1 phút | Chặt, tưới, câu, đánh, giải 1 câu đố nhỏ | Vật phẩm, XP kỹ năng |
| 1 giờ game (10 phút thực) | Hoàn thành 1 việc cụ thể (thu hoạch luống, dọn hang, 1 bài học) | Xu, XP, tiến độ nhiệm vụ |
| 1 ngày | Chu trình: chăm nông trại → đi học/đi làm nhiệm vụ → khai thác/câu cá → ngủ | Tổng kết ngày, mở thêm nhiệm vụ |
| 1 mùa (7 ngày) | Hoàn thành 1–2 chương cốt truyện + lễ hội mùa | Mở map/kỹ năng/công trình |
| 1 năm | Thu thập đủ 5 Mảnh Sao, khôi phục Ngôi Sao Tri Thức | Kết thúc chính, tiếp tục chơi tự do |

### 1.3 Triết lý học tập

- Câu đố nằm **trong thế giới** (cửa khóa, máy móc, tính tiền, đổi vật phẩm) chứ không phải bài kiểm tra tách rời.
- 5 mảng tri thức: **Số (Toán), Chữ (Ngữ văn), Ngữ (Tiếng Anh), Vật (Khoa học tự nhiên), Ký (Lịch sử – Địa lý).**
- Độ khó **thích ứng** theo 5 bậc; sai không bị phạt, chỉ giảm số sao đánh giá.
- Có thể mở rộng ngân hàng câu hỏi bằng file JSON/CSV mà không cần sửa code.

---

## 2. Quy chuẩn kỹ thuật

| Hạng mục | Quy chuẩn |
| --- | --- |
| Engine | Godot 4.3+ (Forward+ tắt, dùng Compatibility/Mobile renderer cho 2D nhẹ) |
| Viewport gốc | 320×180, stretch mode `canvas_items`, aspect `keep`, scale nguyên (×4 = 720p, ×6 = 1080p) |
| Texture | Filter Nearest, tắt mipmap, snap 2D transform vào pixel |
| Tile | 16×16; nhân vật 16×32 (chân ở nửa dưới); NPC cùng chuẩn |
| Khung hình | 60 FPS, physics 60 Hz |
| Sắp xếp chiều sâu | Y-Sort bật cho lớp «Entities»; vật thể cao dùng điểm gốc ở chân |
| Dữ liệu | Resource `.tres` cho item/quest/monster/crop/animal; JSON cho ngân hàng câu hỏi và lịch NPC |
| Lưu game | JSON mã hóa nhẹ, 3 ô lưu + autosave mỗi lần ngủ, có `save_version` để migrate |
| i18n | `localization/*.csv`, khóa dạng `ITEM_TOMATO_NAME` |
| Plugin gợi ý | Dialogue Manager (hội thoại), GUT (unit test) |
| Giấy phép asset | Kiểm tra giấy phép thương mại trước khi dùng. Nguồn tham khảo: Sprout Lands, Ninja Adventure (CC0), LimeZu Modern Interiors |

### 2.1 Physics layers (đặt tên trong Project Settings)

| Layer | Tên | Dùng cho |
| --- | --- | --- |
| 1 | `world_solid` | Tường, nước sâu, vách đá, công trình |
| 2 | `player` | Nhân vật chính |
| 3 | `npc` | NPC |
| 4 | `monster` | Quái vật |
| 5 | `animal` | Động vật nuôi và hoang dã |
| 6 | `interactable` | Vật thể tương tác (Area2D) |
| 7 | `hitbox_player` | Đòn đánh của người chơi |
| 8 | `hitbox_monster` | Đòn đánh của quái |
| 9 | `pickup` | Vật phẩm rơi trên đất |
| 10 | `trigger` | Cổng map, vùng sự kiện, vùng câu cá |

---

## 3. Cấu trúc thư mục dự án

```
res://
├── project.godot
├── addons/                      # dialogue_manager, gut
├── assets/
│   ├── art/
│   │   ├── characters/          # body, eyes, hair, tops, bottoms, shoes, hats, accessories, tool_overlays
│   │   ├── tilesets/            # spring, summer, autumn, winter, interior, shared
│   │   ├── buildings/  props/  items/  plants/  animals/  monsters/
│   │   ├── fx/                  # mưa, tuyết, lá rơi, hạt sáng, hit_spark
│   │   ├── ui/                  # khung, nút, icon, bar
│   │   └── portraits/           # chân dung NPC khi hội thoại
│   ├── audio/  (bgm/, sfx/, ambience/)
│   ├── fonts/
│   └── shaders/                 # palette_swap, water, fog, snow_overlay, outline
├── data/
│   ├── items/  crops/  animals/  monsters/  quests/  npcs/  recipes/
│   ├── questions/               # ngân hàng câu hỏi theo môn: math.json, literature.json, english.json, science.json, history_geo.json
│   ├── schedules/               # lịch NPC theo ngày
│   ├── weather/  loot_tables/  shops/
│   └── balance/                 # xp_curve.tres, price_table.tres
├── scenes/
│   ├── core/        # boot.tscn, main.tscn, title_screen.tscn, loading_screen.tscn
│   ├── maps/        # farm_main.tscn, town_square.tscn, ...
│   ├── buildings/   # exterior/ và interior/
│   ├── entities/    # player/, npc/, monsters/, animals/, plants/, pickups/
│   ├── ui/          # hud/, menus/, dialogs/, shop/, quest_log/
│   ├── minigames/   # math/, literature/, english/, science/, history_geo/, fishing/
│   └── fx/          # weather/, lighting/, hit_effects/
├── scripts/
│   ├── autoload/    # game_clock, weather_system, season_system, event_bus, save_manager,
│   │                # inventory_manager, quest_manager, knowledge_manager, audio_manager,
│   │                # scene_manager, item_database, settings_manager
│   ├── components/  # health_component, stamina_component, hitbox, hurtbox, interactable,
│   │                # inventory_component, equipment_component, state_machine, loot_dropper
│   ├── resources/   # class ItemData, CropData, AnimalData, MonsterData, QuestData, MapStateData...
│   ├── systems/     # farming, fishing, combat, crafting, shop, npc_schedule, spawn_director
│   ├── entities/    # player.gd, npc.gd, monster.gd, animal.gd, plant.gd
│   ├── ui/
│   └── utils/
├── localization/
├── tests/           # GUT
└── docs/            # GDD, API notes, changelog
```

**Quy ước đặt tên:** file và biến `snake_case`; class `PascalCase`; signal là động từ quá khứ (`item_added`, `quest_completed`); hằng số `UPPER_SNAKE_CASE`; scene và script cùng tên.

### 3.1 Autoload (singleton) và trách nhiệm

| Autoload | Trách nhiệm |
| --- | --- |
| `EventBus` | Tập hợp signal toàn cục, không chứa logic |
| `GameClock` | Thời gian, ngày, tuần, mùa, năm; phát tín hiệu mỗi phút game |
| `SeasonSystem` | Bộ tileset/bảng màu theo mùa, tuổi cây, hoạt động theo mùa |
| `WeatherSystem` | Sinh thời tiết có seed, dự báo, điều kiện đặc biệt |
| `SceneManager` | Chuyển map, fade, giữ vị trí vào/ra cổng |
| `InventoryManager` | Túi đồ, hotbar, rương, quy tắc xếp chồng |
| `QuestManager` | Trạng thái nhiệm vụ, mục tiêu, phần thưởng |
| `KnowledgeManager` | Ngân hàng câu hỏi, bậc khó, điểm 5 mảng tri thức |
| `SaveManager` | Lưu/tải toàn bộ, migrate phiên bản |
| `AudioManager` | Nhạc theo map/giờ/thời tiết, hiệu ứng âm thanh |
| `ItemDatabase` | Tra cứu `ItemData` theo `item_id` |
| `SettingsManager` | Âm thanh, phím, ngôn ngữ, trợ năng |

---

## 4. Hệ thống thời gian, mùa và thời tiết

### 4.1 Hằng số thời gian

- **1 ngày game = 24 giờ game = 240 phút thực = 14.400 giây thực.**
- **1 giờ game = 10 phút thực. 1 phút game = 10 giây thực.**
- Đồng hồ HUD nhảy theo bước **10 phút game (= 100 giây thực)**; nội bộ tính liên tục để ánh sáng chuyển mượt.
- Ngày mới bắt đầu lúc **06:00**. Người chơi chơi được từ 06:00 đến **02:00 sáng hôm sau** (20 giờ game = 200 phút thực). 40 phút thực còn lại (02:00–06:00) bị **bỏ qua** khi ngủ.
- **Tạm dừng thời gian** khi: mở menu/túi đồ, hội thoại, cutscene, đang ở màn đố/học. **Thời gian vẫn chạy** trong công trình và khi câu cá/đánh quái.
- Tuần 7 ngày (Thứ Hai → Chủ Nhật). **1 mùa = 7 ngày = 1 tuần**, nên ngày 1 mỗi mùa luôn là Thứ Hai và ngày 7 là Chủ Nhật (ngày lễ hội).
- Năm = 4 mùa = 28 ngày: **Xuân → Hạ → Thu → Đông**.

```gdscript
# scripts/autoload/game_clock.gd (khung tối giản)
extends Node

const REAL_SECONDS_PER_GAME_DAY: float = 14400.0
const GAME_MINUTES_PER_DAY: int = 1440
const DAY_START_MINUTE: int = 360        # 06:00
const FORCED_SLEEP_MINUTE: int = 1560    # 26:00 = 02:00 hôm sau
const DAYS_PER_SEASON: int = 7
const SEASONS_PER_YEAR: int = 4

signal minute_changed(total_minute_of_day: int)
signal hour_changed(hour: int)
signal day_started(day_index: int)
signal season_changed(season_index: int)
signal forced_sleep_triggered

var total_game_minutes: float = 360.0
var is_time_paused: bool = false

func _process(delta_seconds: float) -> void:
	if is_time_paused:
		return
	var game_minutes_per_real_second: float = float(GAME_MINUTES_PER_DAY) / REAL_SECONDS_PER_GAME_DAY
	total_game_minutes += delta_seconds * game_minutes_per_real_second
```

### 4.2 Các pha trong ngày và ánh sáng

Giờ mặt trời mọc (S) và lặn (D) thay đổi theo mùa (mục 4.3). Ánh sáng dùng `CanvasModulate` nội suy theo bảng, kết hợp `PointLight2D` cho đèn.

| Pha | Khoảng giờ | Màu CanvasModulate | Hiệu ứng đi kèm |
| --- | --- | --- | --- |
| Bình minh | S−1h → S+1h | `#FFC9A0` | Sương mỏng, tiếng chim, bóng dài hướng tây |
| Sáng | S+1h → 11:00 | `#FFFFFF` | Nền tảng, NPC ra khỏi nhà |
| Trưa | 11:00 → 15:00 | `#FFFFF0` | Bóng ngắn nhất, nóng hơn (mùa Hạ) |
| Chiều | 15:00 → D−1h | `#FFF0C8` | Ánh vàng, bóng dài hướng đông |
| Hoàng hôn | D−1h → D+1h | `#E8A0A0` → `#8070B0` | Đèn đường bật, đom đóm xuất hiện |
| Tối | D+1h → 23:00 | `#5060A0` | Quái đêm xuất hiện, cửa hàng đóng |
| Khuya | 23:00 → S−1h | `#3A4478` | Chỉ còn đèn nhà, nhắc người chơi đi ngủ từ 00:00 |

Bóng đổ: sprite bóng đơn giản xoay và co theo giờ (không dùng shadow động tốn kém). Đèn tự bật khi `light_level` < 0.55.

### 4.3 Bốn mùa

| Mùa | Mọc / Lặn | Bảng màu và tileset | Địa hình đặc trưng | Nhiệt độ gốc |
| --- | --- | --- | --- | --- |
| Xuân | 06:00 / 19:00 | Xanh non, hồng đào | Hoa nở, cỏ cao, suối đầy | 22°C |
| Hạ | 05:30 / 20:00 | Xanh đậm, vàng nắng | Cây um tùm, hồ lấp lánh, cát nóng | 33°C |
| Thu | 06:30 / 18:30 | Cam, đỏ, nâu | Lá rụng, bí ngô, nấm mọc nhiều | 20°C |
| Đông | 07:00 / 17:30 | Xanh lạnh, trắng | Tuyết phủ, mặt hồ đóng băng, cây trụi lá | 5°C |

Quy tắc chuyển mùa (lúc 06:00 ngày 1): đổi tileset, đổi hệ thực vật, cây trồng không hợp mùa **héo** (trừ trong Nhà kính), reset bảng cửa hàng theo mùa, bật sự kiện mùa.

### 4.4 Thời tiết cơ bản

**Xác suất theo mùa (% mỗi ngày):**

| Thời tiết | Xuân | Hạ | Thu | Đông |
| --- | --- | --- | --- | --- |
| Nắng | 45 | 55 | 35 | 25 |
| Nhiều mây | 15 | 10 | 20 | 25 |
| Mưa phùn | 15 | 5 | 10 | 0 |
| Mưa | 15 | 12 | 20 | 5 |
| Giông bão | 5 | 13 | 5 | 0 |
| Sương mù | 5 | 0 | 10 | 5 |
| Gió lớn | 0 | 0 | 0 | 0 |
| Nóng gay gắt | 0 | 5 | 0 | 0 |
| Tuyết | 0 | 0 | 0 | 30 |
| Bão tuyết | 0 | 0 | 0 | 10 |

*(Gió lớn chỉ xuất hiện như **điều kiện đặc biệt** của mùa Thu, xem 4.5. Hàng này giữ 0 để tổng mỗi cột = 100.)*

**Quy tắc sinh thời tiết (luật riêng):**

1. Dùng RNG có seed: `seed = hash(world_seed, year, season, day)`. Cùng seed ra cùng thời tiết, dễ test và tránh «save scumming».
2. Thời tiết ngày N được sinh khi ngày N−1 bắt đầu, nên luôn có **dự báo** ngày mai (TV, bảng tin quảng trường). Dự báo đúng 90%, sai thì lệch 1 bậc (nắng ↔ mây, mưa ↔ giông).
3. Ngày 1–3 của game và mọi **ngày lễ hội = Nắng**.
4. Không có 2 ngày liên tiếp cùng loại «nặng» (Giông bão, Bão tuyết, Nóng gay gắt).
5. Mỗi ngày có tối đa **2 chuyển pha** (ví dụ: nhiều mây → mưa từ 14:00 → tạnh lúc 18:00), lưu thành `weather_segments`.
6. Mưa tăng `wetness` +0.1 mỗi giờ (tối đa 1), nắng giảm 0.05 mỗi giờ. Tuyết tăng `snow_cover` +0.15 mỗi giờ, nắng tan 0.1 mỗi giờ.

### 4.5 Điều kiện thời tiết đặc biệt

| Điều kiện | Điều kiện kích hoạt | Tác động | Cách đối phó / lợi ích |
| --- | --- | --- | --- |
| Giông sét | Là một dạng của Giông bão | 1%/giờ sét đánh vật cao nhất ngoài trời; quái điện xuất hiện | Cọc thu lôi bảo vệ bán kính 8 ô; rơi «Mảnh Sét» |
| Sương Quên | 5–10% vào Xuân/Thu/Đông, thường lúc bình minh | Tầm nhìn giảm (shader, bán kính 6 ô); Ma Sương xuất hiện; nguy cơ trúng trạng thái «Quên» | Đèn Lồng Tri Thức; thu hoạch nấm hiếm |
| Nóng gay gắt | 5% mùa Hạ | Tiêu hao thể lực ngoài trời +25%; đất khô lúc 12:00 (phải tưới lần 2) | Nước mát, kem, mũ rộng vành; cá nổi gần bờ |
| Bão tuyết | 10% mùa Đông | Tốc độ ngoài trời −20%; mất 1 HP/10 giây nếu không mặc Áo Ấm; cửa hàng ngoài trời đóng | Áo Ấm, lò sưởi; mặt hồ đóng băng, mở lỗ câu cá băng |
| Gió lớn | 15% các ngày Thu (cộng thêm) | Lá và hạt bay; cây rụng thêm hạt | Hái hạt dẻ, hạt giống +30%; mini-game thả diều |
| Mưa sao băng | 4% đêm quang bất kỳ mùa nào | 1–3 điểm «Bụi Sao» xuất hiện ngoài trời | Nhặt trước 02:00; mở nhiệm vụ ẩn |
| Trăng Tròn | Đêm ngày 4 mỗi mùa | Bầy sói có Alpha, quái tinh anh +20%; chỉ lúc này mới nở «Hoa Nguyệt» | Rừng nguy hiểm hơn nhưng thưởng cao |
| Cầu vồng | 10% sau ngày mưa, khoảng 15:00–17:00 | Buff May mắn +10 trong ngày | Cá Cầu Vồng dễ xuất hiện ở Hồ Gương |
| Lễ hội | Ngày 7 mỗi mùa | Map lễ hội mở, cửa hàng thường đóng, nhiệm vụ sự kiện | Xem mục 9 |

### 4.6 Tác động của thời tiết lên các hệ thống

| Thời tiết | Cây trồng | Câu cá | Quái vật | NPC | Thể lực / HP |
| --- | --- | --- | --- | --- | --- |
| Nắng | Bình thường | Bình thường | Bình thường | Lịch thường | Bình thường |
| Mưa / Mưa phùn | **Tự tưới** cây ngoài trời | +20% tỉ lệ cắn câu, cá mưa xuất hiện | Slime mực nhiều hơn | Phần lớn ở trong nhà | Không đổi |
| Giông bão | Tự tưới; nguy cơ sét | Cá điện | Quái điện | Ở trong nhà | Sét gây 30 HP nếu bị đánh |
| Sương mù | Bình thường | Cá hiếm hơn | Ma Sương, tầm nhìn thấp | Đi chậm | Nguy cơ «Quên» |
| Nóng gay gắt | Mất nước nhanh | Cá lặn sâu | Ít quái | Ra bóng râm | +25% thể lực ngoài trời |
| Tuyết | Cây ngoài trời không mọc (trừ ô sương giá) | Câu băng | Sói tuyết | Mặc áo ấm | Chậm 10% |
| Bão tuyết | Như tuyết | Chỉ câu băng | Nhiều sói tuyết | Ở trong nhà | Chậm 20%, mất HP nếu không ấm |

### 4.7 `MapStateData` — trạng thái của một map

Mỗi map giữ một Resource mô tả **trạng thái hiện tại**, các hệ thống khác chỉ đọc nó:

| Trường | Kiểu | Ý nghĩa |
| --- | --- | --- |
| `map_id` | String | Định danh map |
| `season` | enum | Xuân/Hạ/Thu/Đông |
| `time_phase` | enum | Bình minh … Khuya |
| `light_level` | float 0–1 | Điều khiển đèn, bóng |
| `weather_segments` | Array | Danh sách {giờ bắt đầu, loại thời tiết} |
| `special_flags` | Array\[String\] | `fog_of_forgetting`, `full_moon`, `meteor_shower`, `rainbow`, `festival` |
| `wetness` | float 0–1 | Vũng nước, đất ướt |
| `snow_cover` | float 0–1 | Lớp tuyết phủ |
| `temperature` | int | °C, ảnh hưởng trang bị/hiệu ứng |
| `is_open` | bool | Công trình/khu vực có mở cửa không |
| `event_overlay` | String | Trang trí lễ hội |

**Thứ tự áp dụng hiển thị:** tileset theo mùa → lớp tuyết phủ → độ ướt (vũng nước) → CanvasModulate theo pha → hạt thời tiết (mưa, tuyết, lá) → hiệu ứng đặc biệt (sương, sao băng) → gợi ý UI.

---

## 5. Thế giới: Thị trấn Sao Mai và các khu vực

### 5.1 Sơ đồ kết nối

```
                    [Núi Mây]
                        |
 [Rừng Thì Thầm]--[Đồi Thư Viện]--[Hồ Gương & Sông Bạc]
       |                |                    |
 [Hầm Đá Thì Thầm] [Quảng Trường]----[Bãi Biển Sóng Vàng]
                   /    |     \
  [Nông Trại]--[Phố Chợ]  [Trường Ánh Dương]
       |
 [Đồng Cỏ Cỏ Xanh]
```

Nông Trại còn nối trực tiếp với Rừng Thì Thầm (lối tắt phía bắc, mở sau chương 1).

### 5.2 Danh sách map

| ID | Tên | Kích thước (tile) | Chủ đề và vai trò | Mở khóa |
| --- | --- | --- | --- | --- |
| `farm_main` | Nông Trại Mầm Xanh | 80×60 | Nhà người chơi, đất canh tác, chuồng trại, nhà kính, silo | Từ đầu |
| `ranch` | Đồng Cỏ Cỏ Xanh | 60×44 | Trại của cô Mai, bãi chăn thả, mua động vật | Từ đầu (shop mở sau chương 1) |
| `market_street` | Phố Chợ | 56×32 | Tiệm tạp hóa, lò rèn, phòng khám, quán ăn | Từ đầu |
| `town_square` | Quảng Trường Sao Mai | 64×48 | Trung tâm làng, bảng nhiệm vụ, đài phun nước, sân lễ hội | Từ đầu |
| `school_grounds` | Trường Ánh Dương | 48×36 | Lớp học, sân trường, vườn thực nghiệm | Từ đầu (lớp mở sau chương 1) |
| `library_hill` | Đồi Thư Viện | 40×32 | Thư viện cổ, bảo tàng, hầm sách | Từ đầu (hầm sách khóa đến chương 3) |
| `whispering_forest` | Rừng Thì Thầm | 90×70 | Hái lượm, chặt cây, quái nhẹ, bầy sói đêm | Sau chương 1 |
| `stone_mine` | Hầm Đá Thì Thầm | 40 tầng × 40×30 | Khai thác khoáng, quái, boss ở tầng 10/20/30/40 | Chương 1 và Cấp Cư Dân ≥ 3 |
| `mirror_lake` | Hồ Gương & Sông Bạc | 60×44 | Câu cá, vịt trời, cầu gỗ, thác nhỏ | Từ đầu |
| `golden_beach` | Bãi Biển Sóng Vàng | 70×40 | Thủy triều, cua, bến cảng, thủy thủ ngoại quốc | Sau nhiệm vụ sửa cầu Hồ Gương |
| `cloud_mountain` | Núi Mây | 80×80 | Leo núi, đài thiên văn, đỉnh tuyết quanh năm | Chương 5 và Cấp Cư Dân ≥ 8 |

### 5.3 Hồ sơ từng map: công trình, trạng thái đặc thù và quy luật riêng

| Map | Công trình và khu vực chức năng | Trạng thái / quy luật đặc thù |
| --- | --- | --- |
| Nông Trại | Nhà (nâng cấp 3 bậc), hòm gửi hàng, giếng, chuồng gà, chuồng bò, silo, nhà kính, khu đất canh tác 24×16 ô, bãi đá và gốc cây cần dọn | Mỗi ô đất có trạng thái: cỏ → đã cuốc → đã tưới → đã bón → đã gieo. Mưa tự tưới. Qua ngày: ô không tưới trở lại "khô". Đổi mùa: cây trái mùa héo. Không có quái ban ngày, quái nhẹ lẻ tẻ vào đêm trăng tròn |
| Đồng Cỏ | Nhà cô Mai, bãi cỏ chăn thả, chuồng mẫu, bảng giá động vật | Cỏ mọc lại 1 ô/ngày vào Xuân-Hạ-Thu, chết dần vào Đông. Mưa làm cỏ mọc nhanh gấp đôi |
| Phố Chợ | Tiệm tạp hóa, Lò rèn, Phòng khám, Quán Hương Lúa, sạp ngoài trời | Cửa hàng chỉ mở theo giờ (mục 5.5). Chợ phiên Chủ Nhật có sạp phụ. Bão tuyết đóng sạp ngoài trời |
| Quảng Trường | Đài phun nước, bảng nhiệm vụ hàng ngày, bảng tin dự báo thời tiết, ghế đá, sân khấu lễ hội | Là điểm hẹn NPC. Đài phun nước đóng băng vào Đông. Ngày lễ: dựng sân khấu và gian hàng |
| Trường Ánh Dương | Lớp học chính, phòng thí nghiệm, sân bóng, vườn thực nghiệm, phòng hiệu trưởng | Lớp học diễn ra 08:00–10:00 và 14:00–16:00 ngày thường. Cuối tuần: sân trường mở, lớp đóng |
| Đồi Thư Viện | Thư viện cổ (2 tầng), bảo tàng nhỏ, hầm sách bị khóa, vườn đọc sách | Vườn đọc có băng ghế dưới tán cây, mùa Thu lá vàng rơi. Hầm sách chỉ mở sau chương 3 |
| Rừng Thì Thầm | Lối mòn, khoảng trống nấm, gốc cổ thụ, trại thợ rừng, hang sói | Ban ngày yên bình (hái lượm), ban đêm sói và slime mực xuất hiện. Sương Quên làm rừng nguy hiểm gấp đôi |
| Hầm Đá | Sảnh hầm (thang máy, lều nghỉ), 40 tầng sinh ngẫu nhiên theo seed ngày | Không bị ảnh hưởng thời tiết. Mỗi tầng có cầu thang xuống, rương, điểm đào. Tầng sinh lại mỗi ngày |
| Hồ Gương & Sông Bạc | Bến câu, cầu gỗ, nhà thuyền, thác nhỏ, bãi sậy | Mặt hồ đóng băng vào Đông, nước lên cao sau mưa lớn (cầu ngập 1 ngày). Đom đóm vào đêm Hạ |
| Bãi Biển | Cầu cảng, nhà ngư dân, hang đá thủy triều, bãi san hô | **Thủy triều** chu kỳ 6 giờ game (xuống thấp tiết lộ ao nước đọng chứa vỏ sò, sao biển). Giông bão làm sóng cao, cấm xuống mép nước |
| Núi Mây | Đường mòn leo, trạm dừng chân, thác, đài thiên văn trên đỉnh | Tuyết phủ quanh năm từ độ cao 2. Sương mù dày vào sáng sớm. Trên đỉnh nhìn thấy sao rõ hơn (nhiệm vụ thiên văn) |

### 5.4 Chuyển map

- Cổng chuyển map là node `MapPortal` (Area2D, layer `trigger`) có `target_map_id`, `target_spawn_id`, `unlock_conditions[]`.
- Hiệu ứng: mờ dần 0,25 giây → tải scene → mờ hiện 0,25 giây. Thời gian game vẫn chạy.
- Map được **cache** sau lần tải đầu (giữ trạng thái đất, rương, vật rơi). Thực thể có `persistent_id` để lưu/khôi phục.
- Camera mỗi map có `limit_*` đúng kích thước map, theo nhân vật với độ trễ nhẹ (smoothing 6).
- Chuyển vào công trình dùng cùng cơ chế nhưng sang scene nội thất riêng, nhạc nền riêng.

### 5.5 Giờ hoạt động (mặc định, NPC và cửa hàng)

| Địa điểm | Giờ mở | Ngày nghỉ |
| --- | --- | --- |
| Tiệm tạp hóa | 09:00–19:00 | Chủ Nhật (chợ phiên thay thế) |
| Lò rèn | 10:00–17:00 | Thứ Bảy |
| Phòng khám | 08:00–16:00 | Không nghỉ (cấp cứu 24/7, trả phí) |
| Quán Hương Lúa | 11:00–22:00 | Không nghỉ |
| Thư viện | 09:00–18:00 | Thứ Hai |
| Trường học | Lớp 08:00–10:00, 14:00–16:00 | Thứ Bảy, Chủ Nhật |
| Đài thiên văn | 19:00–02:00 | Không nghỉ |

Ngày lễ hội: mọi cửa hàng thường **đóng**, chỉ gian hàng lễ hội mở. Cửa đóng: nhân vật gõ cửa, NPC trong nhà trả lời một câu theo ngữ cảnh.

---

## 6. Công trình, vật phẩm bên trong và tương tác

### 6.1 Chuẩn thiết kế một công trình

**Bên ngoài (exterior scene):**

- Gồm `BodySprite`, `RoofSprite` (ẩn dần khi nhân vật đi vào vùng phía sau/mái), `DoorPortal`, `CollisionPolygon2D` chỉ phủ phần chân tường, `SignLabel` (biển hiệu có chữ), `LightPoints` (cửa sổ phát sáng khi light\_level < 0,55).
- Cửa luôn có **1 ô trống phía trước** để nhân vật đứng; ô này là điểm spawn khi ra khỏi nhà.
- Kích thước chuẩn: nhỏ 4×4 ô (chuồng gà), vừa 6×5 (tiệm), lớn 9×7 (trường, thư viện).

**Bên trong (interior scene):**

- Nhiều lớp TileMap: `Floor`, `Wall`, `Furniture_Back`, `Entities` (Y-sort), `Furniture_Front`, `Light`.
- Có `SpawnPoint_FromOutside`, `AmbienceBus`, danh sách `InteractableSlot` đặt sẵn.
- Cửa sổ chiếu ánh sáng theo giờ (tia sáng xiên ban ngày, tối đen ban đêm trừ đèn).
- Trong nhà: không có thời tiết, nhưng có **âm thanh mưa/gió** vọng nhẹ qua tường.

### 6.2 Mô hình tương tác (`Interactable`)

**Luồng chuẩn (mọi thứ đều đi qua luồng này):**

1. **Phát hiện:** `InteractionDetector` (Area2D hình chữ nhật 20×20 lệch về hướng nhân vật đang nhìn). Chọn mục tiêu ưu tiên: NPC > Trạm (Station) > Rương > Vật trang trí; hòa thì chọn gần nhất.
2. **Gợi ý:** viền sáng (shader outline) + icon phím "E" nổi phía trên + 1 dòng mô tả ngắn.
3. **Kiểm tra điều kiện:** vật đang cầm, kỹ năng, giờ, nhiệm vụ, thể lực.
4. **Thực hiện:** nhấn thường (E) hoặc giữ 0,5 giây (hành động quan trọng/phá hủy).
5. **Hoạt ảnh và âm thanh** của nhân vật và vật thể.
6. **Áp dụng kết quả:** thay đổi trạng thái, trao/nhận vật phẩm, mở UI.
7. **Phát tín hiệu** lên `EventBus` (`interacted_with`) để quest, thành tích, âm thanh bắt.
8. **Lưu trạng thái** nếu vật thể có `persistent_id`.

**Các loại tương tác:**

| Loại | Ví dụ | Kết quả |
| --- | --- | --- |
| Examine | Tranh, biển, kệ sách | Hiện 1–2 dòng mô tả, có thể mở manh mối/nhiệm vụ ẩn |
| Talk | NPC | Mở hội thoại, nhận/nộp nhiệm vụ, tặng quà |
| Container | Rương, tủ, thùng | Mở UI kho đồ hai bên |
| Station | Bếp, lò nung, bàn chế tạo, máy ép | Mở UI công thức, chạy quy trình theo thời gian game |
| Shop | Quầy hàng | Mở UI mua/bán |
| Sleep | Giường | Hỏi xác nhận, kết thúc ngày, hiện tổng kết |
| Door | Cửa, cổng | Chuyển map nếu đủ điều kiện, nếu đóng thì gõ cửa |
| Puzzle | Khóa số, bảng chữ, bàn thí nghiệm | Mở mini-game, kết quả mở khóa hoặc trao thưởng |
| UseItemOn | Hạt giống lên đất, chìa khóa lên cửa, thức ăn lên máng | Cần đang cầm đúng vật phẩm |
| Toggle | Đèn, lò sưởi, cửa sổ | Đổi trạng thái bật/tắt |
| Pickup | Vật rơi, cây hái được | Nhận vật phẩm vào túi |

### 6.3 Danh mục công trình và vật phẩm bên trong

**Nhà người chơi** (nội thất nâng cấp 3 bậc: phòng đơn → thêm bếp → thêm tầng hầm và phòng khách)

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Giường | Sleep | E | Qua ngày, hồi thể lực (xem 7.4), lưu tự động |
| Rương cá nhân (×1 → ×3) | Container | E | Cất 36 ô mỗi rương |
| Bếp | Station | E | Nấu món ăn từ nguyên liệu, mất 10–60 phút game |
| Bàn chế tạo | Station | E | Chế tạo công cụ, đồ đặt (mở công thức theo tri thức) |
| Tủ quần áo | Container đặc biệt | E | Mở màn thay đồ (trang bị/thời trang) |
| Bàn học | Puzzle | E | Làm bài ôn tập cá nhân, nhận XP tri thức |
| TV | Examine | E | Xem dự báo thời tiết ngày mai và bản tin làng |
| Lò sưởi | Toggle | E | Mùa Đông: ấm, hồi nhẹ HP khi ngồi cạnh |
| Hòm thư | Container | E (ngoài sân) | Nhận thư, quà, thông báo nhiệm vụ |

**Trường Ánh Dương** (lớp học, phòng thí nghiệm)

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Bàn học sinh (×12) | Puzzle | E khi vào giờ học | Tham gia buổi học: chuỗi 5 câu đố, XP tri thức |
| Bảng đen | Examine/Puzzle | E | Đề bài trong ngày; giải đúng nhận thưởng nhỏ |
| Bàn cô Lan | Talk | E | Giao nhiệm vụ lớp, nhận điểm danh |
| Bàn thí nghiệm | Station/Puzzle | E | Mini-game khoa học: pha chất, nối mạch điện |
| Quả địa cầu, bản đồ | Examine/Puzzle | E | Câu hỏi Sử – Địa, mở bản đồ chi tiết |
| Tủ sách lớp | Container | E | Mượn sách học (vật phẩm "Sách") |
| Chuông trường | Toggle | E | Chỉ dùng trong nhiệm vụ đặc biệt |

**Thư viện cổ** (2 tầng + hầm sách)

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Kệ sách theo môn | Examine/Container | E | Mượn/trả sách, mỗi sách là 1 vật phẩm học |
| Bàn thủ thư | Talk | E | Nhận nhiệm vụ thư viện, gia hạn sách |
| Máy tra mục lục | Puzzle | E | Câu đố sắp xếp, tra tìm nhiệm vụ ẩn |
| Cầu thang xoắn | Door | E | Lên tầng 2 (khu sách cổ) |
| Cửa hầm sách | Door/Puzzle | UseItemOn (Chìa Mực) | Mở hầm bí mật (cốt truyện chương 3) |
| Bảo tàng nhỏ: tủ kính | Examine | E | Mở mục "Bách khoa" khi trưng bày đủ món |

**Tiệm tạp hóa (Dì Năm)**

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Quầy thu ngân | Shop | E | Mua hạt giống, thức ăn gia súc, vật dụng; bán nông sản |
| Kệ hạt giống theo mùa | Examine | E | Hiện danh sách hạt giống đang bán mùa này |
| Bảng giá | Examine/Puzzle | E | Nhiệm vụ toán: tính tiền thối, giảm giá |
| Thùng hàng đặt trước | Container | E (khi có đơn) | Nhận đơn đã đặt |

**Lò rèn (Chú Ba)**

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Lò nung | Station | E | Nung quặng thành thỏi (thời gian game) |
| Đe | Station | E | Nâng cấp công cụ/vũ khí, mất 2 ngày game |
| Giá vũ khí | Shop | E | Mua vũ khí cơ bản |
| Bàn mài | Station | E | Mài lại vũ khí (hồi độ sắc nếu có hệ độ bền) |

**Phòng khám (Bác sĩ Minh)**

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Giường bệnh | Station | E | Trả phí để hồi đầy HP và xóa trạng thái xấu |
| Tủ thuốc | Shop | E | Mua thuốc, thuốc giải "Quên" |
| Bảng cơ thể | Puzzle | E | Câu đố khoa học về cơ thể, mở công thức thuốc |

**Quán Hương Lúa (Chị Vy)**

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Quầy | Shop | E | Mua món ăn có buff |
| Bàn ăn | Examine/Toggle | E | Ngồi ăn: hồi nhanh, trò chuyện NPC ngồi cạnh |
| Thực đơn | Examine | E | Mở công thức món đã học |
| Bảng sự kiện | Examine | E | Hiện thông báo lễ hội |

**Đài thiên văn (Lão Quang)**

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Kính thiên văn | Puzzle | E (ban đêm, trời quang) | Mini-game tìm chòm sao, mở manh mối cốt truyện |
| Bàn tinh tú | Station | E | Đặt Mảnh Sao vào đài, theo dõi tiến độ 5 mảnh |
| Trụ Ngôi Sao | Examine/Puzzle | E | Điểm kết thúc cốt truyện |

**Chuồng gà / Chuồng bò (trên nông trại)**

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Máng ăn | UseItemOn | Cầm cỏ khô + E | Đổ thức ăn, động vật tự ăn |
| Máng nước | UseItemOn | Cầm bình tưới + E | Đổ nước |
| Ổ đẻ / Chỗ vắt sữa | Pickup/UseItemOn | E / cầm xô sữa | Thu trứng, vắt sữa |
| Lò sưởi chuồng | Toggle | E | Mùa Đông giữ ấm cho động vật |
| Cửa chuồng | Toggle | E | Mở thả ra ngoài / đóng giữ ban đêm |
| Bảng thông tin | Examine | E | Xem chỉ số từng động vật |

**Nhà kính và Silo**

| Vật phẩm | Loại | Tương tác | Kết quả |
| --- | --- | --- | --- |
| Luống đất nhà kính | UseItemOn | Giống như đất ngoài trời | Trồng quanh năm, không bị thời tiết |
| Hệ thống tưới tự động | Toggle | E | Mở sau chương 4 |
| Silo | Container đặc biệt | E | Cất cỏ khô (tối đa 240 bó), rút ra khi cho ăn |

### 6.4 Người chơi tương tác với công trình

| Hành động | Cách thực hiện | Điều kiện |
| --- | --- | --- |
| Vào / ra | Đi vào ô cửa hoặc nhấn E | Công trình đang mở, đủ điều kiện mở khóa |
| Gõ cửa | E khi đóng | Luôn được, NPC trả lời |
| Mua / bán | Mở Shop, kéo thả hoặc nhấn Enter | Đủ Xu hoặc có hàng |
| Nhận / nộp nhiệm vụ | Nói chuyện với NPC giao nhiệm vụ | Đúng trạng thái nhiệm vụ |
| Ngủ | Giường → xác nhận | Sau 20:00 mới ngủ được (trừ khi kiệt sức) |
| Học | Bàn học / lớp học | Đúng giờ, đủ thể lực tối thiểu 10 |
| Nấu, chế, nung | Station → chọn công thức | Có nguyên liệu, trạm trống |
| Chữa bệnh | Giường bệnh | Đủ Xu |

---

## 7. Nhân vật người chơi

### 7.1 Tạo nhân vật (ở màn bắt đầu game mới)

- Nhập **tên** và **tên nông trại**; chọn **thú cưng** (mèo hoặc chó, đi theo và là bạn đồng hành, không chiến đấu).
- Ngoại hình: 2 kiểu cơ thể, 8 màu da, 14 kiểu tóc × 16 màu, 8 màu mắt, 3 bộ trang phục khởi đầu.
- Chọn **môn học yêu thích** (1 trong 5): nhận 1 cuốn sách khởi đầu của môn đó và +50 XP tri thức môn đó.
- Xem trước nhân vật xoay đủ 4 hướng, có nút ngẫu nhiên. Mọi lựa chọn ngoại hình đổi được sau ở **Tủ quần áo** trong nhà.

### 7.2 Nhân vật ghép từ các lớp sprite

Mỗi lớp là một spritesheet riêng, **cùng kích thước khung 16×32 và cùng lưới hoạt ảnh**, nên một `AnimationPlayer` điều khiển thuộc tính `frame` của tất cả lớp cùng lúc.

| Thứ tự vẽ (dưới → trên) | Lớp | Ghi chú |
| --- | --- | --- |
| 0 | Bóng (shadow) | Ellipse mờ dưới chân, không đổi |
| 1 | Đồ lưng (balo, áo choàng) | Khi quay lên: vẽ **trên** thân; quay xuống: vẽ **dưới** thân |
| 2 | Thân + đầu (body) | Đổi màu da bằng palette swap |
| 3 | Quần |  |
| 4 | Giày |  |
| 5 | Áo |  |
| 6 | Mắt, mặt | Kính nằm ở lớp phụ kiện mặt |
| 7 | Tóc | Mũ có cờ `hide_hair` để ẩn tóc |
| 8 | Mũ |  |
| 9 | Phụ kiện mặt/cổ |  |
| 10 | Vật phẩm cầm tay (`HandItem`) | Vị trí lấy từ bảng neo tay (7.3) |

- **Bố cục sheet:** mỗi hàng 1 hướng (Xuống, Lên, Trái; Phải = lật ngang Trái), mỗi cột 1 khung hình. Tên file: `{layer}_{style_id}.png`.
- **Palette swap:** sprite gốc dùng 4 sắc độ tham chiếu (viền, tối, chính, sáng). Shader thay thế từng sắc độ bằng 4 màu của người chơi chọn (tóc, da, mắt, áo...), nên 1 sprite cho vô số màu.
- Vật phẩm trang bị bổ sung lớp tương ứng; **không đổi hoạt ảnh gốc**, chỉ thêm/ẩn lớp.

### 7.3 Danh sách hoạt ảnh và neo tay

| Hoạt ảnh | Số khung | FPS | Ghi chú |
| --- | --- | --- | --- |
| `idle` | 2 | 2 | Thở nhẹ; sau 20 giây đứng yên: nhìn quanh |
| `walk` | 6 | 10 | Mỗi hướng |
| `run` | 6 | 14 | Cúi người, bụi chân |
| `tool_swing` | 4 | 14 | Cuốc, rìu, cuốc chim, lưỡi hái |
| `water` | 4 | 10 | Tưới, có nước bắn |
| `attack_*` | 4–5 | 14 | Mỗi loại vũ khí 1 bộ (kiếm, giáo, búa) |
| `fish_cast` / `fish_wait` / `fish_reel` | 5 / 2 / 4 | 10 | Quăng, chờ, kéo |
| `pickup` | 3 | 10 | Cúi nhặt |
| `carry_walk` | 6 | 8 | Bưng vật nặng (đá lớn, thùng) |
| `eat` | 4 | 8 | Ăn/uống |
| `read` | 2 | 3 | Đọc sách (bắt đầu mini-game học) |
| `hurt` | 2 | 12 | Trúng đòn, bật lùi 6 pixel |
| `roll` | 6 | 16 | Lăn né (mở khóa ở 7.7) |
| `faint` | 4 | 6 | Ngất xỉu |
| `sit` / `sleep` | 1 | 0 | Ngồi ghế, nằm giường |

**Bảng neo tay:** file `data/balance/hand_anchors.json`, mỗi dòng `{animation, direction, frame, x, y, rotation, in_front}`. Node `HandItem` đọc bảng này mỗi khung để đặt đúng vị trí cầm công cụ/vũ khí, và `in_front` quyết định vẽ trên hay dưới thân (ví dụ vung rìu về phía lưng thì vẽ dưới).

### 7.4 Trang bị và cách hiển thị

| Ô trang bị | Có sprite? | Chỉ số điển hình | Ghi chú |
| --- | --- | --- | --- |
| Mũ | Có | DEF, chống nóng/lạnh | Mũ rộng vành giảm nóng gay gắt |
| Mặt | Có | May mắn, chống Mù | Kính, khẩu trang |
| Áo | Có | DEF, HP | "Áo Ấm" chống bão tuyết |
| Quần | Có | DEF, Tốc độ |  |
| Giày | Có | Tốc độ, chống trượt băng | Ủng cao su chống bùn |
| Đồ lưng | Có | Sức chứa, mũ rơi lá | Balo mở rộng túi đồ |
| Phụ kiện 1, 2 (nhẫn, vòng cổ) | Không | Chỉ số đặc biệt (xem 8) | Hiện tại trong UI, không hiện trên người |
| Tay chính | Có (HandItem) | Công cụ hoặc vũ khí đang cầm | Lấy từ ô hotbar đang chọn |

- **Thời trang (cosmetic override):** mỗi ô Mũ/Áo/Quần/Giày có thêm ô "Ngoại hình" để hiện đồ khác mà vẫn giữ chỉ số của đồ thật.
- **Bộ trang bị (set):** mặc đủ 3 món cùng bộ nhận thưởng (ví dụ Bộ Thợ Mỏ: +10% tốc độ đào, ánh sáng đầu quanh 5 ô).
- **Màu độ hiếm:** Thường (trắng), Tốt (xanh lá), Hiếm (xanh dương), Sử thi (tím), Huyền thoại (vàng).
- Tùy chọn **"Ẩn mũ"** để nhìn rõ tóc; trang bị vẫn có tác dụng.

### 7.5 Chỉ số, máu và thể lực

| Chỉ số | Giá trị gốc | Tăng theo cấp | Ghi chú |
| --- | --- | --- | --- |
| HP tối đa | 100 | +5 mỗi cấp Cư Dân | Cộng thêm từ trang bị/buff |
| Thể lực tối đa | 200 | +3 mỗi cấp Cư Dân | Ăn món đặc biệt tăng tạm thời |
| Tấn công (ATK) | 5 | +1 mỗi cấp Chiến Đấu | Cộng từ vũ khí |
| Phòng thủ (DEF) | 0 | Từ trang bị | Công thức sát thương ở mục 11 |
| Tốc độ đi / chạy | 64 / 96 px/giây | Từ trang bị, buff | Trên đất bùn/tuyết bị chậm |
| May mắn | 0 | Từ trang bị, buff | 1 điểm = +1% tỉ lệ rơi hiếm, +0,5% chất lượng cao |
| Bán kính hút đồ | 24 px | Từ trang bị | Vật rơi bay về phía nhân vật |
| Tỉ lệ / sát thương chí mạng | 5% / ×1,5 | Từ kỹ năng |  |

**Tiêu hao thể lực:**

| Hành động | Thể lực |
| --- | --- |
| Cuốc, tưới, chặt, đào (công cụ gốc) | 2–3 mỗi lần, nhân hệ số bậc công cụ (Gỗ ×1,0; Đồng ×0,9; Sắt ×0,8; Vàng ×0,7; Tinh Thể ×0,6) và giảm 1% mỗi cấp kỹ năng liên quan |
| Gieo hạt, thu hoạch tay, hái lượm | 0,5 / 0 / 0 |
| Vung vũ khí | 1 |
| Quăng cần câu | 3 |
| Lăn né | 6 |
| Lướt (dash) | 10 |
| Chạy | 0,5 mỗi giây (chỉ khi chạy) |

**Quy tắc thể lực:**

- **Hồi nhẹ:** đứng yên 5 giây thì hồi 2 thể lực mỗi 10 giây.
- **Kiệt sức (thể lực = 0):** tốc độ −40%, **không dùng được công cụ/vũ khí**, vẫn đi và tương tác được. Ăn là hết kiệt sức.
- **Ngủ trước 24:00:** hồi 100% HP và thể lực. **Ngủ 24:00–02:00:** giảm 5% mỗi 10 phút game, thấp nhất 70%.
- **Ngất lúc 02:00:** thức dậy ở nhà (hoặc giường gần nhất) với 50% thể lực, 75% HP, mất 5% Xu (tối đa 500), có thư từ NPC đã đưa về.

**Quy tắc HP:**

- HP về 0: ngất tại chỗ, được đưa về Phòng khám (nếu trong làng) hoặc nhà, mất 10% Xu (tối đa 1.000) và **không mất vật phẩm**. Ở Hầm Đá thì về sảnh hầm.
- Hồi HP tự nhiên: sau 8 giây không bị đánh, +1 HP mỗi 3 giây. Đồ ăn và thuốc hồi nhanh.
- Bất tử 0,6 giây sau mỗi lần trúng đòn (chớp trắng).

**Trạng thái bất lợi:**

| Trạng thái | Hiệu ứng | Thời gian | Cách giải |
| --- | --- | --- | --- |
| Độc | −1 HP mỗi 2 giây | 12 giây | Thuốc giải, ngủ |
| Chậm | Tốc độ −30% | 6 giây | Hết giờ |
| Choáng | Không điều khiển | 1,5 giây | Hết giờ |
| Mù | Tầm nhìn thu hẹp | 8 giây | Rửa mặt ở giếng, thuốc |
| **Quên** | Tên vật phẩm trên hotbar bị che và **xáo vị trí ô** | 20 giây | Thuốc "Tỉnh Táo", hoặc giải 1 câu đố nhanh |
| Lạnh / Nóng | Hồi chậm hơn / tốn thể lực hơn | Theo môi trường | Áo ấm, mũ rộng vành, vào nhà |

**Buff thức ăn:** hầu hết món có thể ăn cho buff 120–300 phút game (20–50 phút thực): +Tốc độ, +May mắn, +Thể lực tối đa tạm, +ATK, chống lạnh/nóng. Chỉ 1 buff thức ăn và 1 buff đồ uống cùng lúc.

### 7.6 Kinh nghiệm và lên cấp

**Hai tầng kinh nghiệm:**

1. **Cấp Cư Dân (1–30):** cấp tổng của người chơi.
2. **5 kỹ năng (cấp 1–10):** Nông nghiệp, Hái lượm, Câu cá, Khai thác, Chiến đấu.
3. Ngoài ra còn **5 mảng Tri thức (cấp 1–10)** ở mục 9.4.

**Công thức:**

- Cấp kỹ năng: tổng XP cần để đạt cấp **L** = `50 × L × (L + 1)` (cấp 1: 100, cấp 5: 1.500, cấp 10: 5.500).
- Cấp Cư Dân: XP cần để lên từ cấp **L** lên **L+1** = `80 + 45L + 5L²` (cấp 1→2: 130; cấp 10→11: 1.030; cấp 29→30: 5.590). Tổng đạt cấp 30 ≈ 64.670 XP.
- Mỗi hành động cho XP kỹ năng; **50% số đó cộng vào XP Cư Dân**. Nhiệm vụ, quái vật, mini-game cộng trực tiếp XP Cư Dân.

**Nguồn XP Cư Dân:**

| Nguồn | XP Cư Dân |
| --- | --- |
| Nhiệm vụ Hàng ngày | 20–40 |
| Nhiệm vụ Riêng lẻ | 50–120 |
| Nhiệm vụ Phụ | 60–150 |
| Nhiệm vụ Cá nhân | 80–200 |
| Nhiệm vụ Sự kiện | 100–300 |
| Nhiệm vụ Ẩn | 150–500 |
| Nhiệm vụ Chính tuyến | 200–600 |
| Nhiệm vụ Đặc biệt | 300–800 |
| Hạ quái | Xem công thức mục 11.4 |
| Phiên học/đố (đạt ≥ 1 sao) | 5–40 theo bậc khó và số sao |
| Khám phá lần đầu (map, vật phẩm, công thức) | 50 / 5 / 10 |

Nhân thưởng theo sao đánh giá: 1 sao ×1,0; 2 sao ×1,25; 3 sao ×1,5.

**Phần thưởng khi lên cấp Cư Dân:**

- Mỗi cấp: +5 HP tối đa, +3 thể lực tối đa, hồi đầy cả hai.
- Cứ 2 cấp: +1 **Điểm Tài Năng** (dùng ở cây tài năng chung: nhặt xa hơn, ngủ hồi nhiều hơn, giảm giá tiệm 2%...).
- Các mốc cấp mở khóa nội dung: cấp 3 Hầm Đá, cấp 5 chuồng bò, cấp 8 Núi Mây, cấp 12 nhà kính, cấp 20 đài thiên văn nâng cao.

**Kỹ năng và nhánh chuyên môn:**

| Kỹ năng | Thưởng mỗi cấp | Cấp 5 (chọn 1) | Cấp 10 (chọn 1) |
| --- | --- | --- | --- |
| Nông nghiệp | +2% cơ hội chất lượng cao | A: Nông phu (+10% giá bán cây trồng) / B: Chăn nuôi gia (+10% giá sản phẩm động vật, hạnh phúc tăng nhanh) | A: Nhà nông học (8% cơ hội thu gấp đôi) / B: Nhà tạo giống (thu thêm hạt giống) |
| Hái lượm | +3% nhặt thêm | A: Thợ rừng (+20% gỗ) / B: Nhà thực vật (thảo dược chất lượng cao) | A: Thợ săn nấm (nấm hiếm) / B: Người tìm kho báu |
| Câu cá | Thanh bắt cá rộng thêm 2 pixel | A: Ngư phủ (+20% giá cá) / B: Thợ đặt bẫy (bẫy cua gấp đôi) | A: Cần thủ huyền thoại (cá hiếm xuất hiện nhiều) / B: Thủy thủ (câu được ở biển sâu) |
| Khai thác | +3% quặng thêm | A: Thợ mỏ (+1 quặng) / B: Nhà địa chất (đá quý gấp đôi) | A: Thợ nung (thỏi nung nhanh gấp đôi) / B: Nhà thám hiểm (xuống tầng nhanh) |
| Chiến đấu | +1 ATK | A: Chiến binh (+10% sát thương) / B: Du hiệp (+15% tốc độ khi chiến đấu, né tốt hơn) | A: Hộ vệ (giảm 10% sát thương nhận) / B: Sát thủ bóng đêm (+25% chí mạng ban đêm) |

### 7.7 Hành động cơ bản và hành động đặc biệt cần mở khóa

**Cơ bản (có từ đầu):**

| Hành động | Phím mặc định | Ghi chú |
| --- | --- | --- |
| Đi | WASD / mũi tên / cần trái | 4 hướng, đi chéo giữ tốc độ chuẩn hóa |
| Chạy | Giữ Shift | Tốn thể lực |
| Tương tác | E | Xem 6.2 |
| Dùng công cụ / vũ khí | J hoặc chuột trái | Theo vật đang cầm |
| Hành động phụ | K hoặc chuột phải | Ví dụ giữ để tưới diện rộng |
| Chọn ô hotbar | 1–0, -, = / cuộn chuột | 12 ô |
| Ăn / dùng | F | Dùng vật phẩm đang cầm |
| Vứt | X | Vứt 1 hoặc cả chồng khi giữ |
| Ngồi | C | Hồi thể lực nhanh hơn 50% khi ngồi ghế |
| Biểu cảm | T | Vòng chọn 6 biểu cảm |
| Túi / Nhật ký / Bản đồ | I / Q / M | Xem 7.8 |

**Đặc biệt (cần mở khóa):**

| Hành động | Mở khóa bằng | Mô tả |
| --- | --- | --- |
| Lăn né (Roll) | Chiến đấu cấp 3 | Lăn 2,5 ô, bất tử 0,3 giây, tốn 6 thể lực |
| Lướt (Dash) | Hoàn thành chương 2 | Lướt 3 ô, phá bụi rậm nhỏ, tốn 10 thể lực |
| Công cụ diện rộng | Công cụ bậc Sắt/Vàng/Tinh Thể | Giữ chuột phải để nạp: 3 ô, 5 ô, 9 ô |
| Thu hoạch quét | Nông nghiệp cấp 5 | Lưỡi hái quét hình quạt 3 ô liền |
| Quăng hoàn hảo | Câu cá cấp 4 | Thả đúng vòng sáng → xa hơn, ít cá nhỏ |
| Đòn xoay | Chiến đấu cấp 6 (kiếm/búa) | Chém vòng 360°, hồi chiêu 4 giây |
| Bơi | Mua Áo Phao (chương 4) | Đi trên nước nông, tốn thể lực mỗi giây |
| Leo vách đá | Khai thác cấp 5 + Móc leo | Leo qua vách thấp ở Núi Mây |
| Thiền | Tri thức Vật cấp 5 | Ngồi hồi 2 lần thể lực, không dùng khi có quái gần |
| Gọi thú cưng tìm đồ | Hoàn thành nhiệm vụ cá nhân với thú cưng | Mỗi ngày 1 lần, tìm vật phẩm gần |

### 7.8 Tiện ích và bố cục giao diện (HUD)

```
┌────────────────────────────────────────────────────────────────┐
│ [Nhiệm vụ đang theo dõi]               ┌───────────────────┐   │
│  • Thu 3 cà rốt (1/3)                  │ 08:40  Thứ Hai    │   │
│  • Gặp cô Lan                          │ Xuân · Ngày 3     │   │
│                                        │ [Nắng] 22°C       │   │
│                                        │ 1.250 Xu          │   │
│                                        └───────────────────┘   │
│                          (khung chơi)                [Minimap] │
│                                                                │
│ HP ████████░░ 80/100                                  Thể lực │
│ [1][2][3][4][5][6][7][8][9][0][-][=]  Hotbar            █ █   │
└────────────────────────────────────────────────────────────────┘
```

| Thành phần | Vị trí | Nội dung và hành vi |
| --- | --- | --- |
| Đồng hồ + lịch + thời tiết | Trên-phải | Giờ (bước 10 phút), thứ, mùa-ngày, icon thời tiết và nhiệt độ, đĩa mặt trời/trăng xoay |
| Xu | Dưới đồng hồ | Số Xu, nhảy số khi nhận/tiêu |
| Thanh HP | Dưới-trái | Thanh ngang, đổi màu đỏ khi < 30%, nhấp nháy khi < 15% |
| Thanh thể lực | Dưới-phải | Thanh dọc, tô vàng khi buff, đỏ khi < 15% |
| Hotbar | Dưới-giữa | 12 ô; ô đang chọn có viền sáng; số lượng ở góc; icon chất lượng ở góc trái dưới |
| Theo dõi nhiệm vụ | Trên-trái | Tối đa 3 nhiệm vụ ghim, thu gọn được |
| Minimap | Góc phải giữa (tùy chọn bật) | Chấm nhân vật, NPC, cổng map |
| Biểu tượng trạng thái | Cạnh thanh HP | Độc, Chậm, Quên, buff thức ăn kèm đếm ngược |
| Thông báo nhặt đồ | Dưới-trái, trên hotbar | Icon + tên + số lượng, tự mất sau 3 giây |
| Banner lên cấp / nhiệm vụ | Giữa-trên | Trượt vào 0,5 giây, giữ 2 giây |
| Gợi ý tương tác | Phía trên vật thể | Icon phím + 1 dòng |

HUD **tự mờ 50%** sau 6 giây không có thay đổi, trở lại đầy đủ khi có sự kiện. Có chế độ ẩn HUD để chụp ảnh.

**Menu chính (phím Tab hoặc I) gồm 10 thẻ:**

| Thẻ | Nội dung |
| --- | --- |
| Túi đồ | 36 ô (3 hàng × 12), thùng rác, tách chồng (giữ Shift), sắp xếp tự động |
| Trang bị | Búp bê nhân vật và các ô trang bị, xem trước thời trang |
| Kỹ năng & Tri thức | 5 kỹ năng, 5 mảng tri thức, nhánh chuyên môn, cây tài năng |
| Nhiệm vụ | Tab theo loại (mục 9), lọc, ghim theo dõi |
| Bách khoa | Cá, thú, quái, cây, khoáng sản đã khám phá |
| Bản đồ | Bản đồ làng và map hiện tại, điểm NPC theo giờ |
| Quan hệ | Danh sách NPC, tim hữu nghị, sở thích, ngày sinh nhật |
| Chế tạo | Công thức đã học, lọc theo trạm |
| Cài đặt | Âm thanh, phím, ngôn ngữ, trợ năng |
| Thoát | Lưu và thoát, về menu chính |

Trợ năng: cỡ chữ 3 mức, chế độ mù màu (đổi bảng màu độ hiếm), giảm rung màn hình, đổi phím, bật phụ đề âm thanh.

---

## 8. Vật phẩm

### 8.1 Cấu trúc dữ liệu `ItemData`

| Trường | Ý nghĩa |
| --- | --- |
| `id` | Định danh duy nhất, ví dụ `crop_tomato` |
| `name_key`, `description_key` | Khóa i18n |
| `category` | Công cụ / Vũ khí / Trang phục / Hạt giống / Nông sản / Hái lượm / Cá / Sản phẩm động vật / Khoáng sản / Nguyên liệu / Món ăn / Đồ đặt / Sách học / Vật phẩm nhiệm vụ / Trang trí |
| `rarity` | Thường, Tốt, Hiếm, Sử thi, Huyền thoại |
| `stack_size` | 999 cho nguyên liệu, 99 nông sản, 1 cho trang bị |
| `sell_price`, `buy_price` | Giá bán, giá mua (Xu) |
| `icon`, `world_sprite`, `held_animation` | Icon 16×16, sprite khi rơi trên đất, kiểu cầm/dùng |
| `equip_slot`, `stat_modifiers` | Ô trang bị và chỉ số cộng |
| `use_effect` | Hồi HP/thể lực, buff, mở công thức, đặt vật thể |
| `tags` | `edible`, `seed`, `ore`, `gift_loved_by:[npc_id]`, `season:[spring]`... |
| `quality_enabled` | Có hỗ trợ chất lượng sao không |

**Chất lượng:** Thường ×1,0 · Bạc ×1,25 · Vàng ×1,5 · Tinh Thể ×2,0 (giá bán). Xác suất theo kỹ năng, phân bón, May mắn và hạnh phúc động vật.

**Giá bán thực tế** = giá gốc × hệ số chất lượng × (1 + hiệu ứng nhánh chuyên môn) × (1 + 0,01 × cấp Tri thức Số, tối đa +10%).

### 8.2 Cách hiển thị vật phẩm

| Nơi hiển thị | Quy cách |
| --- | --- |
| Ô túi/hotbar | Icon 16×16 trên nền ô 20×20, viền màu theo độ hiếm, số lượng góc phải-dưới (font 5×7), ngôi sao chất lượng góc trái-dưới |
| Trên đất (vật rơi) | Sprite 16×16, bóng nhỏ, nhấp nhô ±2 px chu kỳ 1,2 giây, lóe sáng nếu hiếm; tồn tại đến hết ngày |
| Trên người | Tool/vũ khí ở `HandItem`; đồ nặng bưng trước ngực (`carry_walk`); vũ khí cất đeo lưng khi không dùng |
| Tooltip | Tên (màu độ hiếm), loại, mô tả, chỉ số, giá bán, nguồn ("Thu từ: cà chua"), cảnh báo "Chưa học công thức" |
| Bách khoa | Ảnh lớn hơn, nơi tìm thấy, mùa, giờ, thời tiết xuất hiện |

### 8.3 Nhân vật tương tác với vật phẩm

| Hành động | Điều khiển | Điều kiện | Kết quả |
| --- | --- | --- | --- |
| Nhặt | Tự động hút trong bán kính | Túi còn chỗ | Vào túi, hiện toast; túi đầy: vật dội lại và nhắc "Túi đầy" |
| Dùng / ăn | F | Vật ăn/uống/thuốc | Hiệu ứng ngay, 1 vật bị trừ |
| Vứt | X | Vật không phải nhiệm vụ | Rơi dưới chân, có thể nhặt lại sau 1 giây |
| Tách/gộp chồng | Giữ Shift + kéo | Cùng loại | Tách một nửa, gộp tự động |
| Cất vào rương | Mở rương + kéo | Rương còn chỗ | Hai UI kho đồ song song |
| Tặng NPC | Cầm vật + E vào NPC | 1 quà/ngày/NPC | Tăng tim hữu nghị theo sở thích (yêu +80, thích +45, bình thường +20, ghét −40) |
| Bán | Mở Shop | Quầy hàng mở | Nhận Xu theo giá bán thực tế |
| Đặt | Chuột trái ở chế độ đặt | Vật là đồ đặt, ô hợp lệ | Hiện bóng xanh/đỏ để biết hợp lệ |
| Trang bị | Kéo vào ô trang bị / chuột phải | Đúng ô, đủ cấp | Đổi lớp sprite trên người |
| Chế tạo | Mở bàn chế tạo | Có công thức và nguyên liệu | Nhận vật mới theo thời gian trạm |
| Đọc sách | F với "Sách học" | Chưa đọc | Mở phiên học, thưởng XP tri thức, đánh dấu đã đọc |

### 8.4 Hành động của nhân vật đi cùng vật phẩm

| Nhóm vật phẩm | Hoạt ảnh | Điểm neo / hiệu ứng | Âm thanh | Thể lực |
| --- | --- | --- | --- | --- |
| Cuốc | `tool_swing` | Quét xuống ô phía trước, đất lật tung | Tiếng thịch đất | 2 |
| Bình tưới | `water` | Nước bắn ra ô trước, nước giảm trong bình | Róc rách | 2 |
| Rìu | `tool_swing` | Mảnh gỗ bay, cây rung | Cộp | 3 |
| Cuốc chim | `tool_swing` | Tia lửa, mảnh đá vụn | Keng | 3 |
| Lưỡi hái | `tool_swing` | Cỏ cắt bay, quét hình quạt | Xoẹt | 1 |
| Cần câu | `fish_*` | Dây câu vẽ đường cong, phao nhấp nhô | Vút, tõm | 3 |
| Vũ khí | `attack_*` | Hitbox hình cung/đường thẳng/tròn theo loại | Vút, va chạm | 1 |
| Hạt giống | `tool_swing` nhẹ (rải) | Hạt bay xuống ô | Sột soạt | 0,5 |
| Món ăn / thuốc | `eat` | Hiện icon trên đầu, hiệu ứng buff | Nhai/uống | 0 |
| Sách | `read` | Sách mở ở tay, mở màn học | Lật trang | 0 |
| Đèn lồng | Cầm ở tay trái | Ánh sáng bán kính 6 ô | Không | 0 |
| Vật nặng | `carry_walk` | Bưng trước ngực, tốc độ −25% | Hừ | 0 |

### 8.5 Công cụ và vũ khí theo bậc

**Công cụ** (5 bậc, nâng cấp ở Lò rèn bằng thỏi kim loại + Xu, mất 2 ngày game):

| Bậc | Nguyên liệu nâng | Giá Xu | Hệ số sát thương lên cây/đá | Diện rộng |
| --- | --- | --- | --- | --- |
| Gỗ (khởi đầu) | — | — | ×1,0 | 1 ô |
| Đồng | 5 thỏi đồng | 2.000 | ×1,5 | 1 ô (nạp 3 ô) |
| Sắt | 5 thỏi sắt | 5.000 | ×2,0 | 3 ô |
| Vàng | 5 thỏi vàng | 10.000 | ×3,0 | 5 ô |
| Tinh Thể | 5 thỏi tinh thể | 25.000 | ×4,0 | 9 ô |

**Vũ khí (3 loại × 5 bậc):**

| Loại | Hitbox | Tốc độ | Điểm mạnh | ATK bậc 1 → 5 |
| --- | --- | --- | --- | --- |
| Kiếm | Hình cung 90°, tầm 1 ô | Nhanh (0,35 giây) | Cân bằng, đánh nhiều lần | 8 → 28 |
| Giáo | Đường thẳng 2 ô | Vừa (0,5 giây) | Đánh xa, an toàn | 10 → 32 |
| Búa | Vòng tròn 1,5 ô | Chậm (0,8 giây) | Choáng 1 giây, phá đá | 14 → 40 |

### 8.6 Nhóm vật phẩm mẫu (để dựng dữ liệu ban đầu)

| Nhóm | Ví dụ | Ghi chú |
| --- | --- | --- |
| Hạt giống | Giống cải xanh, cà rốt, khoai tây, dâu tây... | Bán ở tiệm tạp hóa, theo mùa |
| Nông sản | Cải xanh, cà rốt, cà chua, bắp, bí ngô, nho | Có chất lượng sao |
| Hái lượm | Dâu rừng, nấm, thảo dược, hạt dẻ, hoa dại | Mọc theo mùa/giờ/thời tiết |
| Khoáng sản | Đồng, sắt, vàng, tinh thể, than, đá quý | Rơi từ đá và quái hầm |
| Cá | Cá chép, cá rô, cá trê, cá chình, cá cầu vồng... | Xem mục 13.3 |
| Sản phẩm động vật | Trứng, sữa, len, mật, lông vũ, nấm cục | Xem mục 10 |
| Nguyên liệu | Gỗ, đá, cỏ khô, sợi, thỏi kim loại, bụi sao |  |
| Món ăn | Cháo gà, bánh bí ngô, canh nấm, nước chanh đá | Học công thức từ NPC/tri thức |
| Trang phục | Mũ rơm, áo len, ủng cao su, áo choàng sao | Mua, thưởng nhiệm vụ, rơi từ quái |
| Sách học | Sách Số học 1, Từ vựng 100 từ, Nhập môn thiên văn | Mở bài học và công thức |
| Vật phẩm nhiệm vụ | Chìa Mực, Mảnh Sao, thư giới thiệu | Không bán, không vứt |

---

## 9. Cốt truyện, nhiệm vụ và hệ thống học tập

### 9.1 Bối cảnh và cốt truyện

Làng Sao Mai nằm giữa năm ngọn đồi. Hàng trăm năm trước, dân làng dựng **Ngôi Sao Tri Thức** trên đài thiên văn, một trụ đá phát sáng giúp cả làng "nhớ": biết chữ, biết tính, biết nghề. Rồi Ngôi Sao vỡ thành 5 **Mảnh Sao** và **Màn Sương Quên** phủ xuống. Dân làng dần quên: trường vắng học trò, sách mờ chữ, mỏ đá lạc lối. Từ nỗi quên đó sinh ra **Quái Quên** (slime mực, dơi giấy, ma sương...).

Người chơi nhận một lá thư từ người họ hàng xa để lại **Nông Trại Mầm Xanh** và một cuốn **Sổ Tay Tri Thức** còn trống. Sổ Tay tự điền dần khi người chơi học và khám phá (chính là các menu Kỹ năng, Bách khoa). Mỗi Mảnh Sao gắn với một mảng tri thức, và được canh giữ bởi một "Bóng Quên" chỉ bị đánh bại bằng **kết hợp chiến đấu và giải đố**.

**Kết thúc:** vào lễ hội **Đêm Sao Rơi** (Đông, ngày 7), người chơi lắp 5 mảnh vào trụ và đối mặt **Kẻ Xóa Chữ**, thực thể sinh ra từ Sương Quên. Đây không phải trận giết chóc: người chơi "nhắc nhớ" bằng các câu đố trong lúc né đòn. Có 3 hậu kết tùy việc đã phát triển Trường, Thư viện hay Nông Trại nhiều nhất.

**Dàn NPC chính:**

| NPC | Vai trò | Nơi ở / làm | Giao loại nhiệm vụ | Sở thích điển hình |
| --- | --- | --- | --- | --- |
| Cô Lan | Giáo viên | Trường Ánh Dương | Chính (Số), Hàng ngày, Cá nhân | Hoa cúc, sách thiếu nhi |
| Bà Tư | Thủ thư | Thư viện cổ | Chính (Chữ), Phụ, Ẩn | Trà, sách cổ |
| Chú Ba | Thợ rèn | Lò rèn | Phụ, Đặc biệt | Khoáng sản, bia |
| Dì Năm | Chủ tiệm tạp hóa | Phố Chợ | Hàng ngày, Riêng lẻ | Bánh ngọt, vải |
| Bác sĩ Minh | Y sĩ | Phòng khám | Phụ, Cá nhân | Thảo dược, nấm |
| Ông Sáu | Ngư dân | Bãi biển / Hồ | Phụ, Sự kiện | Cá, thuốc lá hái |
| Cô Mai | Chủ trại chăn nuôi | Đồng Cỏ | Chính (hướng dẫn), Phụ | Trứng, sữa |
| Lão Quang | Thiên văn gia | Đài thiên văn | Chính (Vật, Ký, kết), Ẩn | Bụi sao, trà đêm |
| Bé Na | Học sinh | Trường / Quảng trường | Hàng ngày, Cá nhân | Kẹo, hoa dại |
| Anh Khoa | Thợ mỏ | Hầm Đá | Chính (Vật), Đặc biệt | Đá quý, đồ nướng |
| Chị Vy | Đầu bếp | Quán Hương Lúa | Hàng ngày, Sự kiện | Nông sản tươi, gia vị |
| Thuyền trưởng Marco | Thủy thủ ngoại quốc | Bến cảng | Chính (Ngữ), Cá nhân | Cá, sách địa lý |

### 9.2 Các chương chính tuyến

Chương mở khi **chương trước đã xong VÀ ngày hiện tại ≥ ngày mở tối thiểu**. Chương không hết hạn; nếu chưa xong trong năm, câu chuyện tiếp tục sang năm sau (các mùa lặp lại).

| Chương | Thời gian mở tối thiểu | Mục tiêu | Mở khóa | Đỉnh điểm |
| --- | --- | --- | --- | --- |
| Mở đầu: Lá Thư | Xuân ngày 1 | Đến nông trại, dọn đất, trồng hạt đầu, gặp Dì Năm, ngủ đêm đầu | Hướng dẫn cơ bản | Nhận Sổ Tay |
| 1. Hạt Giống Đầu Tiên | Xuân 2 | Làm quen toàn bộ NPC, trồng và thu hoạch lần đầu, cô Lan mời vào lớp | Rừng Thì Thầm, sảnh Hầm Đá, nhiệm vụ Hàng ngày | Gặp Lão Quang, biết về Ngôi Sao vỡ |
| 2. Ngôi Trường Im Lặng | Xuân 4 | Sương Quên phủ trường, giải đố Toán để cứu lớp học | Lướt (dash), lớp học đầy đủ | **Mảnh Số** — vượt "Bóng Số Không" trong hầm trường |
| 3. Thư Viện Bị Khóa | Hạ 1 | Tìm Chìa Mực, mở hầm sách, phục hồi sách bị xóa chữ | Hầm sách, công thức nâng cao | **Mảnh Chữ** — vượt "Gã Gạch Xóa" |
| 4. Tiếng Sóng Ngoại Ngữ | Hạ 5 | Sửa cầu, ra biển, giao tiếp với Marco bằng tiếng Anh | Bãi Biển, Áo Phao, nhà kính | **Mảnh Ngữ** — vượt "Thủy Thủ Câm"; Hội Biển Đêm |
| 5. Mỏ Đá Thì Thầm | Thu 1 | Xuống Hầm Đá, giải đố cơ khí và khoa học | Tầng 20–40, Núi Mây | **Mảnh Vật** — vượt "Golem Công Thức" |
| 6. Núi Mây và Ký Ức | Thu 5 | Leo núi, theo dấu di tích, ghép lịch sử ngôi làng | Đài thiên văn nâng cao | **Mảnh Ký** — vượt "Hồn Ký Ức"; Hội Gặt |
| 7. Đêm Sao Rơi | Đông 1 | Lắp 5 mảnh, chuẩn bị lễ hội, đối mặt Kẻ Xóa Chữ | Hậu kết, chế độ chơi tự do mùa 2 | **Kẻ Xóa Chữ** (Đông 7, 20:00) |

Giữa các chương luôn có **thời gian đệm** (vài ngày) để người chơi làm nhiệm vụ phụ, nuôi thú, khai thác; không gò ép tiến độ.

### 9.3 Cơ chế nhiệm vụ

**Dữ liệu `QuestData`:**

| Trường | Ý nghĩa |
| --- | --- |
| `id`, `title_key`, `description_key` | Định danh và nội dung |
| `quest_type` | Một trong 8 loại ở 9.5 |
| `giver_id`, `turn_in_id` | NPC giao / nhận (có thể khác nhau, hoặc rỗng = tự hoàn thành) |
| `prerequisites[]` | Cấp Cư Dân, chương, nhiệm vụ trước, mùa, ngày, thời tiết, hữu nghị, vật phẩm |
| `objectives[]` | Danh sách mục tiêu (xem dưới) |
| `time_limit` | Hạn theo phút game hoặc ngày (tùy chọn) |
| `rating_rules` | Điều kiện được 2 và 3 sao |
| `rewards` | Xu, XP, vật phẩm, tim hữu nghị, mở khóa |
| `repeatable`, `cooldown_days` | Có làm lại được không |

**Loại mục tiêu (`objective.type`):** `collect` (có vật phẩm), `deliver` (giao vật cho NPC), `kill` (hạ quái), `reach` (đến vị trí), `talk` (nói chuyện), `craft`, `plant`, `harvest`, `fish`, `feed_animal`, `solve_puzzle` (đạt ≥ số sao), `survive` (trụ qua giờ), `explore`, `use_item_on`. Mục tiêu chạy **tuần tự** hoặc **song song**, có thể đánh dấu **tùy chọn** (để lấy sao).

**Trạng thái:** `Locked` → `Available` → `Active` → `Ready` (đủ mục tiêu, chờ nộp) → `Completed` → `Claimed`; nhánh phụ: `Failed`, `Expired`.

**Giao nhiệm vụ:**

| Kênh | Dấu hiệu | Dùng cho |
| --- | --- | --- |
| NPC | Dấu `!` trên đầu: **vàng** Chính, **xanh dương** Phụ, **xanh lá** Hàng ngày, **hồng** Cá nhân, **tím** Đặc biệt, **cam** Sự kiện | Hầu hết loại |
| Bảng nhiệm vụ Quảng Trường | Giấy ghim, 3 nhiệm vụ Hàng ngày mới lúc 06:00 | Hàng ngày, Riêng lẻ |
| Hòm thư | Thư mới sáng sớm | Cá nhân, Sự kiện |
| Vùng kích hoạt (trigger) | Không dấu | Nhiệm vụ Ẩn |
| Vật phẩm | Đọc sách/nhật ký nhặt được | Phụ, Ẩn |

**Hoàn thành:**

1. Hệ thống nghe `EventBus` và cập nhật tiến độ mục tiêu (toast "Cà rốt 2/3").
2. Khi mọi mục tiêu bắt buộc xong: `Ready`, dấu `?` hiện trên NPC nhận. Nhiệm vụ không có NPC nhận sẽ tự hoàn thành.
3. Nộp: hội thoại ngắn, tính sao, phát thưởng, banner hiện lên.

**Đánh giá sao:**

| Sao | Điều kiện chung |
| --- | --- |
| 1 sao | Hoàn thành mục tiêu bắt buộc |
| 2 sao | Thêm 1 điều kiện phụ: đúng hạn sớm, độ chính xác ≥ 80%, không bị thương, hoặc nộp kèm vật chất lượng ≥ Bạc |
| 3 sao | Thêm điều kiện ẩn/khó: không sai câu nào, hạ gọn không dùng thuốc, chất lượng Vàng... |

**Phần thưởng gốc (nhân ×1,0 / ×1,25 / ×1,5 theo sao):**

| Loại | Xu | Phần thưởng khác |
| --- | --- | --- |
| Hàng ngày | 80–200 | Nguyên liệu, +10 hữu nghị |
| Riêng lẻ | 150–400 | Đồ đặt nhỏ |
| Phụ | 300–800 | Công thức, trang phục |
| Cá nhân | 200–500 | +100 hữu nghị, sự kiện tim |
| Sự kiện | 400–1.000 | Vật phẩm lễ hội độc quyền |
| Ẩn | 500–1.500 | Vật hiếm, bí mật |
| Chính tuyến | 800–3.000 | Mảnh Sao, mở khóa lớn |
| Đặc biệt | 1.500–5.000 | Trang bị Sử thi, nhánh tài năng |

Nhiệm vụ lớn cho **chọn 1 trong N** phần thưởng. XP Cư Dân theo bảng ở 7.6.

**Thất bại và hết hạn:** không phạt nặng. Hết hạn chỉ mất phần thưởng; nhiệm vụ Phụ/Cá nhân có thể được NPC giao lại sau `cooldown_days`. Nhiệm vụ Chính tuyến không hết hạn.

### 9.4 Hệ thống Tri thức và học tập

**Năm mảng tri thức** (cấp 1–10, dùng cùng công thức XP của kỹ năng: tổng XP cần = `50 × L × (L + 1)`):

| Mảng | Môn | Mini-game / dạng đố | Nơi học | Thưởng mỗi cấp |
| --- | --- | --- | --- | --- |
| **Số** | Toán | Tính nhẩm nhanh (tiệm tạp hóa), dãy số quy luật, đo diện tích luống (lưới), cân thăng bằng | Trường, tiệm tạp hóa, bàn học | +1% giá bán (tối đa +10%), giảm giá khi mua 1% (tối đa 10%) |
| **Chữ** | Ngữ văn | Điền từ vào ca dao/tục ngữ, ghép câu, sắp xếp đoạn, đoán chữ (kiểu Wordle), chính tả | Thư viện, bàn học | +2% hiệu quả quà tặng, mở lời thoại đặc biệt, +1% XP mọi nguồn |
| **Ngữ** | Tiếng Anh | Nối từ với hình, điền câu, hội thoại chọn câu đáp (với Marco) | Bến cảng, lớp học, sách ngoại ngữ | Mở sạp thương lái nước ngoài, giá bán đồ hiếm +2%, nhận thư/nhiệm vụ tiếng Anh |
| **Vật** | Khoa học tự nhiên | Pha trộn chất, nối mạch điện, chuỗi thức ăn, vòng đời cây, dự báo thời tiết | Phòng thí nghiệm, phòng khám, Hầm Đá | Cây lớn nhanh hơn 1% (tối đa 10%), mở công thức thuốc và máy móc, tăng hiệu quả buff thức ăn |
| **Ký** | Lịch sử – Địa lý | Sắp xếp mốc thời gian, nối địa danh với bản đồ, đố di tích | Thư viện, Núi Mây, đài thiên văn | +1 May mắn mỗi 2 cấp, mở chi tiết bản đồ và đường tắt |

**Cấu trúc một phiên học:**

- 5 câu hỏi, có thể xen kẽ nhiều dạng. Thời gian game **tạm dừng** trong phiên.
- Sao: ≥ 60% đúng = 1 sao; ≥ 80% = 2 sao; 100% hoặc (bậc 4–5 sai tối đa 1 câu) = 3 sao.
- Thưởng theo sao: XP tri thức, XP Cư Dân, và vật phẩm nhỏ ở lần đầu mỗi ngày.
- Sai: hiện **giải thích**, không phạt. Sai 3 câu liên tiếp được mời "Học lại bài này" (xem giải thích trước khi thử lại).

**Độ khó thích ứng (5 bậc):** tăng 1 bậc sau 2 phiên liên tiếp ≥ 80%; giảm 1 bậc sau 2 phiên liên tiếp < 40%. Người chơi có thể ghim bậc thủ công ở Cài đặt (cho phụ huynh/giáo viên).

**Ngân hàng câu hỏi (`data/questions/*.json`):**

```json
{
  "id": "math_0012",
  "subject": "math",
  "type": "numeric_input",
  "difficulty": 2,
  "tags": ["phep_nhan", "cua_hang"],
  "prompt_key": "Q_MATH_0012_PROMPT",
  "answer": 36,
  "hint_key": "Q_MATH_0012_HINT",
  "explanation_key": "Q_MATH_0012_EXPLAIN"
}
```

Các `type` hỗ trợ: `multiple_choice`, `fill_blank`, `ordering`, `matching`, `numeric_input`, `drag_to_sort`, `grid_puzzle`. Ngân hàng nạp lúc khởi động; thêm câu hỏi chỉ cần thêm dòng JSON.

**Ôn tập ngắt quãng đơn giản (Leitner 3 hộp):** câu trả lời đúng 3 lần liên tiếp chuyển sang hộp "đã thuộc" (gặp lại ít); câu sai quay về hộp 1 (gặp lại nhiều).

**Câu đố trong thế giới (không phải mini-game bảng):** cửa khóa dãy số, bảng chữ trên tường cần điền, cân thăng bằng cho cửa đá, mê cung la bàn (Địa lý) ở Núi Mây, bảng tuần hoàn rút gọn ở phòng thí nghiệm.

**Không chặn cứng cốt truyện:** nếu thất bại 3 lần ở một câu đố Chính tuyến, Lão Quang xuất hiện "giúp một tay" và cho qua với 1 sao. Từ màn hình Tiêu đề có **Phòng học** (chế độ ôn luyện tự do, không cần chơi game).

### 9.5 Định nghĩa tám loại nhiệm vụ

| Loại | Định nghĩa | Ai giao / kích hoạt | Hạn | Cách theo dõi | XP Cư Dân | Dấu hiệu |
| --- | --- | --- | --- | --- | --- | --- |
| **Chính tuyến** | Mạch truyện chính (mục 9.2), mỗi chương gồm 4–8 nhiệm vụ nối tiếp | NPC chính, trigger theo chương | Không hết hạn | Ghim tự động, nền vàng | 200–600 | `!` vàng |
| **Phụ** | Câu chuyện nhỏ về NPC hoặc địa phương, tự chọn | NPC, thư, vật phẩm | Có thể có hạn dài (7 ngày) | Thẻ "Phụ" | 60–150 | `!` xanh dương |
| **Hàng ngày** | Công việc lặp lại, tạo mới 06:00 mỗi ngày, tối đa 3 cái | Bảng Quảng Trường, Dì Năm, Chị Vy | Hết ngày | Thẻ "Hôm nay" | 20–40 | `!` xanh lá |
| **Riêng lẻ** | Việc làm một lần, ngắn, không thuộc chuỗi (ví dụ "đưa hộp này cho ông Sáu") | Bảng, NPC bất kỳ | Thường 1–3 ngày | Thẻ "Việc lặt vặt" | 50–120 | Giấy ghim |
| **Cá nhân** | Dành cho từng NPC, mở theo mức hữu nghị (2, 4, 6, 8, 10 tim), gắn sự kiện tim | NPC đó | Không | Thẻ "Tâm tình" | 80–200 | `!` hồng |
| **Đặc biệt** | Thử thách lớn, mở theo cấp hoặc thành tựu (thợ mỏ, thợ săn, đầu bếp) | NPC chuyên môn | Không | Thẻ "Thử thách" | 300–800 | `!` tím |
| **Sự kiện** | Chỉ trong lễ hội/sự kiện mùa | NPC lễ hội | Hết lễ hội | Thẻ "Lễ hội" | 100–300 | `!` cam |
| **Ẩn** | Không hiện trong nhật ký đến khi kích hoạt bằng khám phá/điều kiện lạ | Trigger, vật phẩm, điều kiện thời tiết/giờ | Tùy | Hiện thẻ khi kích hoạt | 150–500 | Không có |

**Ví dụ nhiệm vụ ẩn:** *Đêm có mưa sao băng*: nhặt 3 Bụi Sao trước 02:00 và đặt lên Bàn Tinh Tú. *Cuốn nhật ký ướt*: khi trời mưa, ghé ghế đá Vườn Thư Viện lúc 16:00 để thấy một trang giấy lộ chữ.

### 9.6 Khi nào nhiệm vụ được cấp

| Giai đoạn | Loại nhiệm vụ mở thêm |
| --- | --- |
| Ngày 1 (Mở đầu) | Chính (Mở đầu), 1–2 Riêng lẻ hướng dẫn |
| Sau Chương 1 | Hàng ngày (bảng Quảng Trường), Phụ đầu tiên (Dì Năm, Cô Mai), Cá nhân (mốc 2 tim) |
| Cấp Cư Dân 5 | Đặc biệt đầu tiên (Thử thách Thợ Mỏ, Thử thách Đầu Bếp) |
| Sau Chương 2 | Sự kiện (lễ hội), Ẩn đầu tiên, Phụ liên quan trường học |
| Sau Chương 3 | Phụ thư viện, Ẩn trong hầm sách, Đặc biệt học giả |
| Sau Chương 4 | Phụ biển/cảng, nhiệm vụ buôn bán quốc tế, Đặc biệt ngư phủ |
| Cấp Cư Dân 12+ | Nhiệm vụ Cá nhân mốc 6–10 tim, Ẩn mức hiếm |
| Sau Chương 7 | Nhiệm vụ "Sau Kết thúc" (xây dựng làng, mở rộng), mùa 2 lặp lại có biến thể |

### 9.7 NPC, hữu nghị và lịch sinh hoạt

- **Hữu nghị 0–10 tim**, mỗi tim = 100 điểm. Nguồn điểm: nói chuyện (+20/ngày), quà (xem 8.3), nhiệm vụ Cá nhân, tham dự lễ hội cùng NPC. Mỗi 2 tim mở một **sự kiện tim** (đoạn cutscene ngắn) và nhiệm vụ Cá nhân.
- **Lịch sinh hoạt** lưu JSON trong `data/schedules/`, theo loại ngày: `weekday`, `weekend`, `rain`, `festival`, `special`. Mỗi dòng `{start_minute, map_id, position_marker, activity}`; NPC đi theo đường điều hướng (`NavigationAgent2D`) giữa các điểm.
- **Mưa/bão:** NPC chuyển lịch `rain` (ở trong nhà, tiệm đông hơn). **Sương Quên:** một vài NPC biến mất khỏi lịch vì "quên đường", đó là một vụ hấp dẫn cho nhiệm vụ Ẩn.
- Hội thoại viết bằng Dialogue Manager, có nhánh theo hữu nghị, theo mùa, theo thời tiết, theo nhiệm vụ đang làm.

### 9.8 Lễ hội và sự kiện mùa

| Lễ hội | Thời điểm | Nội dung | Nhiệm vụ Sự kiện |
| --- | --- | --- | --- |
| Hội Hoa Xuân | Xuân ngày 7 | Triển lãm hoa, cuộc thi cắm hoa (Chữ + Số) | Thu thập 5 loại hoa, trang trí gian hàng |
| Hội Biển Đêm | Hạ ngày 7 | Thả đèn nước, thi câu cá ban đêm, đom đóm | Giải đố tiếng Anh với khách nước ngoài |
| Hội Gặt | Thu ngày 7 | Thi nông sản, nấu ăn, trò kéo co | Nộp nông sản chất lượng cao, thi hát ca dao |
| Đêm Sao Rơi | Đông ngày 7 | Lễ chính của cốt truyện, mưa sao băng đặc biệt | Kết thúc chương 7; năm sau trở thành lễ hội vui |

Mọi lễ hội: thời tiết luôn Nắng (hoặc quang đãng ban đêm), cửa hàng thường đóng, bản đồ Quảng Trường chuyển sang `event_overlay`, thời gian lễ hội 10:00–23:00.

---

## 10. Động vật

### 10.1 Phân loại

- **Vật nuôi (livestock):** gà, vịt, bò, dê, cừu, heo, ong, ngựa. Người chơi mua, nuôi, thu sản phẩm. **Không có mổ thịt**; muốn bớt vật nuôi thì "nhượng lại" cho cô Mai với 50% giá mua.
- **Thú cưng:** mèo/chó (miễn phí, chọn ở đầu game), có nhiệm vụ cá nhân riêng.
- **Động vật hoang:** sống trong map, tương tác để khám phá Bách khoa, một số cho vật phẩm (10.5).

### 10.2 Bảng vật nuôi: giá, sản phẩm, kinh nghiệm

| Vật nuôi | Công trình cần | Giá mua (Xu) | Trưởng thành | Thức ăn / ngày | Sản phẩm (chu kỳ) | Giá bán sản phẩm | XP Nông nghiệp mỗi lần thu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Gà | Chuồng gà | 400 | 3 ngày | 1 cỏ khô | Trứng (mỗi ngày); Lông vũ (5%/ngày) | 50; 90 | 6 |
| Vịt | Chuồng gà cấp 2 + ao | 650 | 4 ngày | 1 cỏ khô + nước | Trứng vịt (mỗi 2 ngày); Lông vũ vịt (10%) | 110; 100 | 9 |
| Bò sữa | Chuồng bò | 1.500 | 5 ngày | 2 cỏ khô | Sữa bò (mỗi ngày) | 125 | 12 |
| Dê | Chuồng bò cấp 2 | 2.000 | 5 ngày | 2 cỏ khô | Sữa dê (mỗi 2 ngày) | 220 | 16 |
| Cừu | Chuồng bò cấp 2 | 2.500 | 6 ngày | 2 cỏ khô | Len (mỗi 3 ngày, cần Kéo cắt) | 340 | 20 |
| Heo | Chuồng bò cấp 3 | 5.000 | 7 ngày | 3 cỏ khô | Nấm cục (heo tự tìm ngoài trời, không mưa/Đông) | 625 | 30 |
| Ong | Tổ ong (đặt trên đất) | 1.000 | Ngay | Hoa trong 5 ô | Mật ong (mỗi 4 ngày) | 180 (hương vị theo hoa) | 10 |
| Ngựa | Chuồng ngựa | 8.000 | 8 ngày | 3 cỏ khô | Không có; cưỡi (tốc độ +40%, không dùng được công cụ) | — | — |
| Mèo / Chó | Bát ăn | 0 | — | 1 thức ăn thú cưng | Mang vật nhỏ về nhà (1 lần/ngày sau nhiệm vụ cá nhân) | — | — |

**Sản phẩm chế biến (trạm trên nông trại):** Máy mayonnaise (trứng → mayonnaise), Máy phô mai (sữa → phô mai), Máy dệt (len → vải), Thùng ủ mật (mật → rượu mật ong).

### 10.3 Cơ chế sinh tồn của vật nuôi

Mỗi con có các chỉ số sau (lưu trong `AnimalState`):

| Chỉ số | Thang | Thay đổi theo thời gian | Hậu quả khi thấp |
| --- | --- | --- | --- |
| Đói | 0–100 | −4 mỗi giờ game | < 30: sản lượng giảm 50%; 0 qua 1 ngày: Ốm |
| Khát | 0–100 | −5 mỗi giờ game (vịt −8) | Như Đói |
| Hạnh phúc | 0–1.000 | +10/ngày vuốt ve; +20 khi ra bãi cỏ; +20 khi ăn cám cao cấp; −50 khi bị đói; −100 khi ở ngoài trời cả đêm; −150 khi quái tấn công | Ảnh hưởng chất lượng và sản lượng |
| Sức khỏe | 0–100 | −10 mỗi ngày Ốm; Ốm do đói, khát, lạnh Đông không có lò sưởi, mưa bão ngoài trời | Ốm: ngừng sản xuất, cần thuốc thú y |
| Nhiệt (chuồng) | Ấm / Lạnh | Mùa Đông cần lò sưởi chuồng | Lạnh: Sức khỏe giảm, Hạnh phúc giảm |

**Quy trình mỗi ngày (06:00):** hệ thống tính từng con: đủ ăn uống? → có Ốm? → sinh sản phẩm theo chu kỳ → quyết định chất lượng sản phẩm.

| Hạnh phúc | Chất lượng sản phẩm (xác suất) |
| --- | --- |
| < 300 | 100% Thường |
| 300–599 | 85% Thường, 15% Bạc |
| 600–799 | 55% Thường, 35% Bạc, 10% Vàng |
| ≥ 800 | 30% Thường, 40% Bạc, 25% Vàng, 5% Tinh Thể |

**Chăm sóc hằng ngày của người chơi:**

| Việc | Cách làm |
| --- | --- |
| Cho ăn | Đổ cỏ khô vào máng (hoặc cho gặm cỏ ngoài bãi khi trời tốt) |
| Cho uống | Đổ nước từ bình vào máng nước |
| Vuốt ve | E vào con vật (+10 hạnh phúc, 1 lần/ngày/con) |
| Mở/đóng cửa chuồng | Thả ra bãi chăn lúc sáng; **đóng lại trước 19:00** kẻo quái/cáo |
| Dọn chuồng | Nhặt phân (cho phân bón miễn phí) |
| Chữa bệnh | Thuốc thú y từ Bác sĩ Minh (1 chai/lần) |

**Môi trường sống:**

- **Gà, vịt:** chuồng gà + sân thả; vịt cần ao nước. Không ở ngoài khi mưa lớn.
- **Bò, dê, cừu:** chuồng + **bãi cỏ** (cỏ mọc theo mùa, mục 5.3). Ăn cỏ ngoài trời thì không tốn cỏ khô và tăng hạnh phúc. Tự động vào chuồng khi mưa lớn/bão.
- **Heo:** cần khu đất ngoài trời có cây để tìm nấm cục.
- **Ong:** cần hoa trong 5 ô, ngừng hoạt động khi mưa và mùa Đông.
- **Ngựa:** chuồng ngựa có mái, cần chải lông định kỳ để giữ hạnh phúc.
- **Nguy hiểm ban đêm:** cáo và sói tấn công con vật ở ngoài hoặc chuồng không đóng cửa. Có chó trông nhà thì rủi ro giảm 70%.

### 10.4 Công trình và thức ăn cho động vật

| Công trình | Cấp / sức chứa | Chi phí | Chức năng |
| --- | --- | --- | --- |
| Chuồng gà | Cấp 1: 4 con. Cấp 2: 8 con + máng tự động. Cấp 3: 12 con + lò ấp trứng | 4.000 Xu + 300 gỗ + 100 đá. Cấp 2: 10.000 + 400 gỗ. Cấp 3: 20.000 + 600 gỗ | Nhà, ổ đẻ, máng, lò sưởi (cấp 2+) |
| Chuồng bò | Cấp 1: 4 con. Cấp 2: 8 con. Cấp 3: 12 con | 8.000 Xu + 400 gỗ + 150 đá. Cấp 2: 15.000. Cấp 3: 28.000 | Bò, dê, cừu, heo (theo cấp) |
| Chuồng ngựa | 1 con | 10.000 Xu + 100 sắt | Ngựa cưỡi |
| Silo | 240 bó cỏ khô | 100 Xu + 50 đá + 10 đồng thỏi | Cất cỏ khô |
| Máng nước | Theo chuồng | 200 Xu | Cấp nước |
| Ao vịt | 2×3 ô | 500 Xu + 50 đá | Vịt bơi, hạnh phúc +20 |
| Tổ ong | 1 tổ | 1.000 Xu hoặc chế tạo | Sản xuất mật |
| Hàng rào | Mỗi ô | 10 gỗ | Giữ vật nuôi ngoài trời trong khu |

**Thức ăn:**

| Loại | Nguồn | Giá | Hiệu quả |
| --- | --- | --- | --- |
| Cỏ khô | Cắt cỏ bằng lưỡi hái (40% rơi 1 bó), mua ở tiệm | 50 Xu/bó | Đủ ăn |
| Cám ngũ cốc | Chế biến từ bắp, lúa | 120 Xu | Đủ ăn + 20 hạnh phúc |
| Thức ăn thú cưng | Quán Hương Lúa, tiệm | 40 Xu | Giữ hạnh phúc thú cưng |

### 10.5 Động vật hoang

| Tên | Môi trường | Thời điểm | Hành vi | Tương tác | Vật phẩm |
| --- | --- | --- | --- | --- | --- |
| Thỏ rừng | Rừng, Đồng Cỏ | Sáng, chiều | Nhảy loanh quanh, chạy khi lại gần | Cho ăn cà rốt, làm quen | Lông thỏ (rụng tự nhiên), mở Bách khoa |
| Chim sẻ | Mọi map ngoài trời | Ban ngày, không mưa | Mổ hạt, bay khi lại gần | Rải hạt giống làm quen | Hạt giống (hiếm) |
| Vịt trời | Hồ Gương, sông | Sáng, chiều | Bơi theo đàn | Cho ăn bánh mì | Lông vũ, trứng vịt trời |
| Ếch | Hồ, bãi sậy | Mưa, đêm | Kêu theo nhịp | Bắt bằng vợt | Nhờ ếch, mở nhiệm vụ ẩn |
| Cua | Bãi biển | Thủy triều thấp | Bò ngang | Bắt bằng bẫy | Cua, vỏ cua |
| Bướm | Rừng, nông trại | Xuân–Hạ, nắng | Bay quanh hoa | Vợt côn trùng | Phấn bướm (nguyên liệu) |
| Đom đóm | Hồ, rừng | Đêm Hạ | Phát sáng nhấp nháy | Vợt | Bột sáng (nguyên liệu đèn) |
| Hươu | Rừng, Núi Mây | Sáng sớm, hiếm | Chạy khi bị động | Quan sát đứng yên 5 giây | Sừng rụng (Thu), nhiệm vụ ẩn |
| Cú | Rừng, Đài thiên văn | Đêm | Đậu trên cành | Đứng gần Lão Quang | Lông cú, gợi ý nhiệm vụ |
| Cáo | Rừng, rìa nông trại | Đêm | Trộm trứng, dọa vật nuôi | Đuổi bằng chó/đèn | Lông cáo khi chạy mất |

---

## 11. Quái vật

### 11.1 Tổng quan và giao diện

**Quái Quên** sinh ra từ Sương Quên, hình thù gợi sự mờ nhạt của ký ức: mực loang, giấy rách, bóng mờ. Chúng **không rơi máu**, khi bị hạ sẽ tan thành mực/giấy trong 6 khung hoạt ảnh.

**Giao diện quái:**

- Sprite 16×16 (nhỏ), 24×24 (vừa), 32×32 (lớn), 48×48 trở lên (trùm). Biến thể màu theo vùng bằng palette swap.
- **Thanh HP nhỏ** xuất hiện phía trên đầu khi bị đánh, ẩn sau 4 giây.
- Tên và **cấp** hiện khi di chuột/đưa mắt ngắm; tinh anh có viền vàng, Alpha có viền đỏ và kích thước ×1,5.
- Dấu `!` đỏ khi phát hiện người chơi; **vùng đỏ báo hiệu** (telegraph) trước mỗi đòn mạnh.
- Trúng đòn: nhấp nháy trắng 0,1 giây, bật lùi nhẹ.

### 11.2 Bảng chỉ số quái

| Quái | Vùng và thời điểm | Cấp | HP | ATK | DEF | Tốc độ (px/s) | XP gốc | Vật phẩm rơi |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Slime Mực | Rừng (đêm, mưa); Hầm tầng 1–10 | 1 | 30 | 6 | 0 | 28 | 8 | Mực Quên (80%), Gel (30%), Hạt giống hiếm (5%) |
| Sâu Đá | Hầm tầng 1–15 | 2 | 45 | 7 | 3 | 22 | 12 | Đá (90%), Đồng (50%), Than (20%) |
| Dơi Giấy | Hầm 1–20; Hầm sách | 3 | 22 | 8 | 0 | 55 | 10 | Giấy Mục (70%), Trang Sách Rách (25%) |
| Nấm Độc | Rừng (sáng sương, mùa Thu) | 4 | 55 | 9 | 2 | 18 | 16 | Bào Tử (60%), Nấm (50%), Thảo dược (25%) |
| Cua Đá | Bãi biển (sáng, chiều, triều thấp) | 5 | 70 | 10 | 8 | 25 | 20 | Càng Cua (60%), Vỏ sò (40%) |
| Quái Điện | Mọi map ngoài trời khi giông | 7 | 50 | 15 | 0 | 60 | 30 | Mảnh Sét (40%), Đồng (20%) |
| Nhện Hang | Hầm 11–30 | 8 | 80 | 14 | 4 | 48 | 28 | Tơ Nhện (70%), Sắt (30%) |
| Sói Bóng Đêm | Rừng đêm; Núi Mây | 9 | 110 | 18 | 5 | 70 | 40 | Lông Sói (60%), Móng Sói (25%) |
| Ma Sương | Khi có Sương Quên; Núi Mây sáng sớm | 10 | 60 | 16 | 0\* | 40 | 35 | Tinh Sương (50%), Bụi Sao (2%) |
| Linh Băng | Đông; Núi Mây | 11 | 120 | 20 | 6 | 40 | 50 | Tinh Băng (50%), Bạc (15%) |
| Sách Hộ Pháp | Hầm sách | 12 | 160 | 22 | 10 | 30 | 60 | Trang Sách Cổ (60%), Chìa Mực (nhiệm vụ) |
| Golem Đá | Hầm tầng 25–40 | 15 | 300 | 30 | 20 | 20 | 90 | Tinh Thể (40%), Vàng thỏi (20%), Đá quý (30%) |

*\*Ma Sương: DEF 0, nhưng nhận **chỉ 50% sát thương** khi đứng ngoài vùng sáng; trong vùng ánh sáng đèn lồng nhận 100%.*

**Công thức sát thương:**

- `sát_thương = max(1, round(ATK_công × 100 / (100 + DEF_thủ) × ngẫu_nhiên(0,9; 1,1)))`, nhân chí mạng nếu có.
- Chỉ số quái **tăng theo tầng hầm:** HP × `(1 + 0,12 × (tầng − 1))`, ATK × `(1 + 0,08 × (tầng − 1))`.

### 11.3 Phương thức tấn công, kỹ năng và hiệu ứng

| Quái | Kiểu tấn công | Báo hiệu | Kỹ năng / hiệu ứng đặc biệt |
| --- | --- | --- | --- |
| Slime Mực | Nhảy lao 2 ô | 0,5 giây | Chết thì 30% tách thành 2 slime nhỏ (HP 8); đòn trúng có 5% gây **Mù** |
| Sâu Đá | Chui xuống → trồi lên đánh vòng tròn 1 ô | 0,6 giây | Khi chui xuống miễn sát thương |
| Dơi Giấy | Bay ngoằn ngoèo, lao cắn | 0,3 giây | Khi trúng đòn tản ra thành mảnh giấy rồi gom lại sau 1 giây |
| Nấm Độc | Không đuổi theo; phun bào tử vùng 2,5 ô mỗi 3 giây | 0,4 giây | Gây **Độc**; tiêu diệt bằng giáo từ xa là an toàn nhất |
| Cua Đá | Kẹp càng trước mặt 1 ô | 0,5 giây | Giả làm đá; co vỏ (+10 DEF 3 giây), búa phá được vỏ |
| Quái Điện | Nhảy chớp 3 ô | 0,4 giây | Chạm gây **Choáng** 1,5 giây |
| Nhện Hang | Phun tơ thẳng 4 ô, nhảy 3 ô | 0,5 giây | Tơ gây **Chậm**; đẻ nhện con khi chết (10%) |
| Sói Bóng Đêm | Lao nhào 4 ô | 0,6 giây | **Tru** gọi bầy (thêm 1–2 sói, 1 lần mỗi trận) |
| Ma Sương | Lướt xuyên tường, vồ | 0,5 giây | Gây **Quên** 20 giây; yếu dưới ánh sáng |
| Linh Băng | Bắn tinh băng thẳng, bay 5 ô | 0,6 giây | Gây **Chậm** và **Lạnh** |
| Sách Hộ Pháp | Ném 3 trang sách xoay (hình quạt) | 0,7 giây | Tạo ô "cấm chữ" trên sàn: đứng vào bị Choáng 1 giây |
| Golem Đá | Dậm đất vòng tròn 2 ô; ném đá 5 ô | 0,9 giây | Dậm: **Choáng**; phá được bằng búa ở giáp lưng |

**Máy trạng thái AI (`StateMachine`):**

`Idle` → `Wander` → `Alert` (0,4 giây, dấu !) → `Chase` → `Telegraph` → `Attack` → `Recover` (0,5–1 giây) → quay lại `Chase`; nhánh phụ: `Flee` (khi HP < 20%, chỉ một số loại), `Stunned`, `Dead`.

- **Phát hiện:** bán kính 6–9 ô, mất dấu sau 2 giây ngoài tầm nhìn.
- **Dây xích (leash):** rời tổ hơn 12 ô thì quay về và hồi 5% HP mỗi giây.
- **Điều hướng:** `NavigationAgent2D`, tránh vật cản và nước sâu.
- **Trạng thái gây ra** dùng đúng danh sách ở mục 7.5.

### 11.4 Kinh nghiệm và vật phẩm khi hạ quái

**XP Cư Dân khi hạ quái** = `XP_gốc × hệ_số_phẩm × hệ_số_chênh_cấp`

- `hệ_số_chênh_cấp = clamp(1 + 0,1 × (cấp_quái − Cấp_Cư_Dân), 0,25; 1,5)`.
- XP **Chiến đấu** nhận thêm = 60% con số trên (không áp dụng quy tắc 50% chung nữa).

| Phẩm | Hệ số XP | Số lượt rơi vật phẩm | Ghi chú |
| --- | --- | --- | --- |
| Thường | ×1 | 1 | Bảng rơi ở 11.2 |
| Tinh anh | ×2,5 | 2 | Thêm rơi hiếm |
| Alpha (thủ lĩnh bầy) | ×4 | 3 | 1 lượt chắc chắn là hiếm |
| Mini-boss | ×10 | 4 + rương | Vật phẩm độc quyền |
| Boss / Bóng Quên | ×25 | Bảng riêng + rương lớn | Mảnh Sao (nếu là Bóng Quên) |

- **May mắn** của người chơi cộng 1% mỗi điểm vào tỉ lệ rơi vật phẩm hiếm.
- Vật rơi nằm trên đất đến hết ngày; túi đầy thì bật dội lại.

### 11.5 Vùng hoạt động và quy tắc xuất hiện (`SpawnDirector`)

| Vùng | Điều kiện xuất hiện | Quái và số lượng tối đa |
| --- | --- | --- |
| Rừng Thì Thầm | Ban ngày: chỉ Nấm Độc khi sương/mùa Thu. Từ 20:00: nhiều quái | Slime Mực ×6, Sói Bóng Đêm ×2 (Alpha 20%; Trăng Tròn 60%), Nấm Độc ×3 |
| Hầm Đá tầng 1–10 | Luôn luôn | Slime Mực, Sâu Đá, Dơi Giấy; **Boss tầng 10: Slime Mực Mẹ** |
| Hầm Đá tầng 11–20 | Luôn luôn | Thêm Nhện Hang, Nấm Độc; **Boss tầng 20: Chúa Dơi Giấy** |
| Hầm Đá tầng 21–30 | Luôn luôn | Thêm Quái Điện, Golem nhỏ; **Boss tầng 30: Golem Công Thức** (Bóng Quên của Mảnh Vật) |
| Hầm Đá tầng 31–40 | Luôn luôn | Golem Đá, Nhện Hang, Ma Sương, nhiều tinh anh; **Boss tầng 40: Hầm Vương** |
| Hầm sách | Sau chương 3 | Dơi Giấy, Sách Hộ Pháp; **Gã Gạch Xóa** |
| Bãi biển | Sáng–chiều khi triều thấp; đêm có Ma Sương | Cua Đá ×5 |
| Núi Mây | Quanh năm, sương sớm | Sói Bóng Đêm, Linh Băng, Ma Sương; **Hồn Ký Ức** |
| Nông trại, Làng | Không xuất hiện (vùng an toàn), trừ đêm Trăng Tròn | Vài Slime Mực lạc vào nông trại |

**Quy tắc chung:** sinh ngoài tầm nhìn (≥ 12 ô), tối đa theo bảng, nhóm 2–4 con, **reset mỗi ngày lúc 06:00** (quái chưa chết biến mất). Thời tiết đổi bảng: mưa +30% Slime Mực; giông thêm Quái Điện; Sương Quên thêm Ma Sương; Đông thay Sói Bóng Đêm bằng Sói Tuyết (cùng chỉ số, +10% HP).

### 11.6 Bầy quái, quái đặc biệt và Bóng Quên

| Loại đặc biệt | Cách nhận biết | Chỉ số | Hành vi / kỹ năng thêm |
| --- | --- | --- | --- |
| **Tinh anh** | Viền vàng | HP +60%, ATK +20% | 1 kỹ năng thêm (ví dụ Sói tinh anh lao 2 lần) |
| **Alpha** (thủ lĩnh bầy) | To ×1,5, viền đỏ, tiếng tru đặc biệt | HP +150%, ATK +30% | Tạo **hào quang** +15% ATK cho bầy trong 5 ô; gọi thêm 2 con; chết thì cả bầy hoảng sợ, bỏ chạy 5 giây |
| **Quái biến dị theo thời tiết** | Đổi màu (Slime Mưa xanh dương, Sói Tuyết trắng) | Nhanh hơn 20% | Hiệu ứng riêng theo thời tiết |
| **Quái Quên Vàng** | Lấp lánh, chạy trốn | HP thấp, tốc độ cao | Hiếm 1%; hạ được rơi **Bụi Sao** |
| **Mini-boss vùng** | Thanh HP lớn trên màn hình | HP ×10 | 2–3 pha, thưởng độc quyền |

**Bầy (`MonsterPack`):** là Resource mô tả tỉ lệ thành viên (ví dụ bầy sói: 2–3 thường + 0–1 Alpha), đội hình (vòng vây, một hàng) và hành vi chung (cả bầy đuổi theo khi một con phát hiện).

**Năm Bóng Quên canh Mảnh Sao (và trùm cuối):** mỗi trận là **chiến đấu + đố**, người chơi không thể chỉ đánh liều.

| Bóng Quên | Địa điểm | Pha chiến đấu | Cách thắng (phần đố) |
| --- | --- | --- | --- |
| Bóng Số Không | Hầm trường | Né các con số rơi từ trần | Ở pha 2, 3 phép tính hiện lên; đánh trúng con số kết quả đúng để làm nứt Số Không |
| Gã Gạch Xóa | Hầm sách | Gạch xóa chữ trên sàn đấu | Điền từ đúng vào câu để khôi phục ô sàn, ô sàn khôi phục thì không bị xóa nữa |
| Thủy Thủ Câm | Bến cảng (trên tàu) | Sóng đánh, mỏ neo quét | Trả lời hội thoại tiếng Anh để "giải bùa im lặng", mỗi câu đúng làm lộ điểm yếu |
| Golem Công Thức | Hầm tầng 30 | Dậm đất, ném đá | Đánh các "khớp" sáng theo đúng thứ tự công thức khoa học (nối mạch) |
| Hồn Ký Ức | Núi Mây | Sương dày, ảo ảnh | Sắp xếp các mốc ký ức theo thứ tự thời gian để mở đường đến Mảnh Ký |
| **Kẻ Xóa Chữ** | Đài thiên văn | 3 pha: xóa chữ, xóa số, xóa ngôn ngữ | Dùng cả 5 mảng tri thức; mỗi mảng đạt cấp cao hơn thì được thêm "nhắc nhớ" (hỗ trợ) |

---

## 12. Cây cối, hoa cỏ và thực vật

### 12.1 Phân loại và cách biểu diễn

| Nhóm | Đại diện | Biểu diễn | Thu hoạch bằng |
| --- | --- | --- | --- |
| Cây trồng | Cà rốt, cà chua, bí ngô... | Thực thể `Plant` trên 1 ô đất | E / lưỡi hái |
| Cây ăn quả | Táo, đào, cam, hồng | Thực thể 3×3 ô (thân + tán) | E vào trái chín / lắc cây |
| Cây rừng | Sồi, thông, phong | Thực thể có HP, thân + tán tách lớp | Rìu |
| Hoa | Cúc, tulip, hướng dương, hoa tuyết | Thực thể 1 ô, trồng hoặc mọc dại | E |
| Cỏ và bụi | Cỏ cao, bụi dâu, bụi rậm | Tile trang trí có hành vi | Lưỡi hái / E |
| Hái lượm | Nấm, dâu rừng, hạt dẻ, tỏi dại | Vật nhỏ mọc ngẫu nhiên | E |

**Quy cách hiển thị:**

- Mỗi cây trồng có **4–6 khung sinh trưởng**: hạt → mầm → non → trưởng thành → **chín** (có điểm nhấn sáng) → héo. Cây cao dùng sprite 16×32 gốc ở chân.
- Ô đất **đã tưới** tối hơn một sắc; ô đã bón có chấm sáng; ô khô trở lại sáng màu khi qua ngày.
- **Gió:** shader làm cây đung đưa nhẹ; gió lớn đung đưa mạnh và rụng lá. Nhân vật đi qua bụi/cỏ cao làm nó rung.
- **Mùa:** cây rừng và cỏ đổi sprite theo mùa (xuân hoa trắng, hạ xanh đậm, thu cam đỏ, đông trụi lá và phủ tuyết khi `snow_cover` > 0,3).
- Y-sort theo điểm gốc; tán cây vẽ ở lớp trên, mờ dần (alpha 60%) khi nhân vật đi sau.

### 12.2 Quy tắc trồng trọt

1. **Cuốc** ô cỏ → ô đất; **gieo** hạt (đúng mùa, đất đã cuốc); **tưới** mỗi ngày (mưa tự tưới ngoài trời).
2. Cây chỉ tăng **1 ngày sinh trưởng** khi ô được tưới trong ngày. Không tưới thì đứng im; **3 ngày liền không tưới** thì héo.
3. Chuyển mùa: cây trái mùa **héo** lúc 06:00 ngày 1 (trong Nhà kính thì không). Khi gieo, UI cảnh báo nếu "không kịp thu hoạch trước khi hết mùa".
4. **Phân bón:** Phân thường (+chất lượng), Phân tăng trưởng (−1 ngày sinh trưởng, tối thiểu 2 ngày), Phân giữ nước (giữ ẩm 1 ngày không cần tưới).
5. **Chất lượng nông sản:** phụ thuộc cấp Nông nghiệp, phân bón, May mắn và tưới đủ liên tục. 
GDD nêu các yếu tố ảnh hưởng chất lượng nông sản nhưng chưa có công thức
6. **Thời tiết:** mưa tự tưới; Nóng gay gắt làm đất khô lúc 12:00; Giông có nguy cơ sét đánh; Tuyết/Bão tuyết giết cây ngoài trời trái mùa.

### 12.3 Bảng cây trồng

| Cây | Mùa | Ngày lớn | Thu lại | Giá hạt | Giá bán | XP Nông nghiệp |
| --- | --- | --- | --- | --- | --- | --- |
| Cải xanh | Xuân | 2 | Không | 20 | 40 | 4 |
| Cà rốt | Xuân | 3 | Không | 30 | 70 | 6 |
| Khoai tây | Xuân | 4 | Không (1–2 củ) | 50 | 110 | 9 |
| Dâu tây | Xuân | 5 | Mỗi 2 ngày | 100 | 120 | 12 |
| Ớt | Hạ | 3 | Mỗi ngày | 40 | 45 | 5 |
| Cà chua | Hạ | 4 | Mỗi 2 ngày | 50 | 80 | 8 |
| Bắp | Hạ | 5 | Mỗi 2 ngày | 150 | 50 | 7 |
| Dưa hấu | Hạ | 6 | Không | 80 | 250 | 22 |
| Khoai lang | Thu | 3 | Không | 60 | 100 | 8 |
| Cà tím | Thu | 4 | Mỗi 2 ngày | 20 | 60 | 7 |
| Nho | Thu | 5 | Mỗi 2 ngày | 60 | 80 | 9 |
| Bí ngô | Thu | 6 | Không | 100 | 320 | 26 |
| Củ cải tuyết | Đông (Nhà kính, ô sương giá) | 3 | Không | 40 | 90 | 7 |
| Nấm tuyết | Đông (Hầm nấm trong nhà) | 4 | Không | 60 | 140 | 10 |

### 12.4 Cây ăn quả

| Cây | Mùa ra quả | Thời gian lớn | Quả mỗi ngày | Giá bán quả | XP |
| --- | --- | --- | --- | --- | --- |
| Đào | Xuân | 5 ngày | 1 (tối đa 3 tích) | 100 | 8 |
| Cam | Hạ | 5 ngày | 1 | 120 | 8 |
| Táo | Thu | 5 ngày | 1 | 140 | 9 |
| Hồng | Thu | 5 ngày | 1 | 160 | 10 |

Cây non cần 3×3 ô trống quanh nó. Ngoài mùa ra quả cây vẫn sống nhưng không ra quả; Mùa Đông trụi lá.

### 12.5 Cây rừng và thu hoạch gỗ

| Cây | Xuất hiện | Độ bền | Vật phẩm rơi | Ghi chú |
| --- | --- | --- | --- | --- |
| Sồi | Rừng, nông trại | 40 | Gỗ ×8–12, Nhựa (30%), Quả sồi (25%) | Cây gỗ phổ biến |
| Thông | Rừng, Núi Mây | 35 | Gỗ ×6–10, Nhựa thông (30%), Hạt thông (25%) | Xanh quanh năm |
| Phong | Rừng (mùa Thu) | 40 | Gỗ ×8–12, Xi-rô phong (khi gắn ống dẫn nhựa) | Lá đỏ rơi mùa Thu |
| Cây già (cổ thụ) | Rừng sâu | 120 | Gỗ cứng ×4, vật phẩm hiếm | Cần Rìu Sắt |

- Số nhát chặt = `ceil(độ_bền / (sát_thương_rìu × hệ_số_bậc))`. Cây đổ ngả **ngược hướng người chơi**, bị chặn bởi vật cản.
- Gốc cây còn lại: cần Rìu Đồng trở lên hoặc cuốc chim để nhổ, rơi thêm gỗ.
- Trồng lại bằng hạt: cây non lớn qua 4 giai đoạn trong 4 ngày. XP Hái lượm: chặt đổ cây 10, nhổ gốc 4.

### 12.6 Hoa, cỏ và bụi

| Loại | Mùa / nơi | Thu hoạch | Vật phẩm |
| --- | --- | --- | --- |
| Hoa cúc, tulip | Xuân | E | Hoa (quà tặng, nguyên liệu nước hoa, mật ong) |
| Hướng dương | Hạ | E | Hoa, hạt hướng dương |
| Cúc vàng | Thu | E | Hoa, dùng cho lễ hội Gặt |
| Hoa tuyết | Đông | E | Hoa hiếm |
| Hoa Nguyệt | Đêm Trăng Tròn, Rừng | E | Nguyên liệu thuốc quý |
| Cỏ cao | Mọi mùa trừ Đông (chết dần) | Lưỡi hái | 40% rơi cỏ khô |
| Bụi dâu | Xuân, Thu | E | Dâu rừng ×2–4, mọc lại sau 2 ngày |
| Bụi rậm | Mọi map | Lưỡi hái / Lướt qua | Gỗ vụn, đôi khi hạt giống |

### 12.7 Hái lượm theo mùa

| Mùa | Rừng / Nông trại | Bờ nước / Biển | Hầm / Núi |
| --- | --- | --- | --- |
| Xuân | Tỏi dại, rau dớn, hoa dại | Rau cải xoong | Tuyết lan (chân núi) |
| Hạ | Dâu rừng, hoa hướng dương dại | Vỏ sò, rong biển | Nấm đá |
| Thu | Nấm, hạt dẻ, mâm xôi | Sò điệp | Nấm hang |
| Đông | Rễ củ, quả cây trụi lá | San hô (biển lặng) | Tinh băng, hoa Nhung Tuyết |

**Quy tắc:** mỗi sáng 06:00 spawn 3–8 vật hái lượm mỗi map; **nấm mọc nhiều hơn sau mưa**; hái được +3 XP Hái lượm; cấp Hái lượm tăng cơ hội chất lượng cao và nhặt thêm.

---

## 13. Sông, núi, biển, hồ

### 13.1 Cách thể hiện chung

- **Nước** là lớp TileMap riêng `Water` dùng tile hoạt hình 4 khung (0,4 giây/khung), viền bờ dùng Terrain autotile (bọt sóng). Nước sâu có va chạm chặn, nước nông cho đi (chậm 30%).
- Shader nước: gợn sóng, phản chiếu mờ bầu trời và bóng cây (cường độ theo `light_level`).
- Mỗi vùng nước có `FishingZone` (Area2D) chứa bảng cá theo mùa/giờ/thời tiết.
- **Địa hình cao (núi)** dùng nhiều `height_level` (0–3): vách đá là tile chặn, bậc thang là tile nối giữa các mức, nhân vật đổi lớp vẽ khi lên cao.

### 13.2 Hồ sơ từng địa hình

| Địa hình | Giao diện | Hiệu ứng / trạng thái | Động vật | Vật phẩm | Tương tác |
| --- | --- | --- | --- | --- | --- |
| **Sông Bạc** | Nước chảy một chiều (tile hoạt hình + đốm bọt), cầu gỗ, đá nổi | Mưa lớn: nước dâng, cầu ngập 1 ngày. Đông: viền sông đóng băng mỏng. Âm thanh róc rách | Cá, vịt trời, ếch, rùa | Sỏi, sậy, cát vàng | Câu cá, đặt bẫy cá, đi trên đá nổi |
| **Hồ Gương** | Mặt hồ phẳng, phản chiếu rõ; sen nở mùa Hạ | Sương sớm; đom đóm đêm Hạ; Đông **đóng băng hoàn toàn**, đi bộ được, đục lỗ câu băng | Cá chép, cá cầu vồng, vịt trời, ếch, đom đóm | Sen, rong hồ, Ngọc Hồ (hiếm) | Câu cá, thả bè (sau Ch4), thả đèn nước (lễ hội) |
| **Bãi biển và biển** | Cát vàng, sóng vỗ vào bờ, hải âu bay | **Thủy triều** 6 giờ game: triều thấp lộ ao nước đọng; giông: sóng cao, cấm mép nước; đêm: đèn bến cảng | Cua, hải âu, sao biển, cá biển, rùa biển (hiếm) | Vỏ sò, san hô, rong biển, chai thư, ngọc trai | Nhặt, đặt bẫy cua, câu biển (cần Áo Phao ở vùng sâu) |
| **Núi Mây** | Vách đá nhiều tầng, đường mòn zig-zag, thác nước hoạt hình + sương | Tuyết phủ từ độ cao 2; sương dày sáng sớm; trời quang đêm: sao rõ nhất | Hươu, chim ưng, sói tuyết, Linh Băng | Quặng lộ thiên, Hoa Nhung Tuyết, tinh băng | Leo vách (Móc leo), cắm trại hồi phục tại trạm dừng chân, quan sát sao |
| **Thác nước** | Dòng nước đổ, màn sương mờ, cầu vồng khi nắng | Âm thanh lớn che tiếng quái | Cá Sao (đêm sao băng) | Đá ẩm, rêu | Câu cá ở chân thác, hang sau thác (nhiệm vụ ẩn) |

**Tương tác của nhân vật với nước:**

| Hành động | Điều kiện | Kết quả |
| --- | --- | --- |
| Múc nước | Cầm bình tưới + E vào nước | Đầy bình |
| Rửa mặt | E vào nước (ở giếng/bờ) | Xóa trạng thái Mù |
| Lội nước nông | Đi vào | Tốc độ −30%, không dùng công cụ |
| Bơi vùng sâu | Có Áo Phao (Ch4) | Đi trên nước sâu, tốn thể lực mỗi giây |
| Đi trên băng | Đông, hồ đóng băng | Trượt nhẹ (giày chống trượt khử hiệu ứng) |

### 13.3 Câu cá

**Cơ chế (3 bước):**

1. **Quăng:** giữ J nạp thanh lực; thả đúng vòng sáng thì "quăng hoàn hảo" (mở khóa Câu cá cấp 4).
2. **Chờ:** dấu `!` xuất hiện sau 0,5–3 giây (mồi tốt rút ngắn). Có 1 giây để nhấn J.
3. **Kéo:** mini-game thanh kiểm soát: con cá di chuyển lên xuống, giữ J để nâng thanh xanh của người chơi, giữ cá nằm trong thanh để đầy thanh tiến độ. Độ khó cá 1–5 quyết định tốc độ và độ giật. **Hoàn hảo** (không để tuột lần nào) thì chất lượng cao hơn và XP ×1,5.

**Cần câu:** Tre (khởi đầu), Sợi Thủy Tinh, Sắt, Vàng, Tinh Thể (nâng cấp ở Lò rèn); cần bậc cao mở vùng sâu và rút ngắn thời gian chờ.

| Cá | Nơi | Mùa | Giờ | Thời tiết | Độ khó | Giá bán | XP Câu cá |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cá bống | Sông | Cả năm | Cả ngày | Mưa | 1 | 30 | 4 |
| Cá chép | Hồ Gương | Xuân–Thu | Cả ngày | Mọi | 2 | 70 | 8 |
| Cá rô | Sông | Xuân, Thu | 06:00–19:00 | Nắng, mây | 2 | 80 | 8 |
| Cá trê | Sông | Hạ, Thu | 18:00–02:00 | Mưa tăng tỉ lệ | 3 | 120 | 12 |
| Cá lóc | Hồ | Hạ | 06:00–12:00 | Nắng | 3 | 150 | 14 |
| Cá cầu vồng | Hồ | Hạ | 10:00–18:00 | Nắng, cầu vồng | 3 | 200 | 16 |
| Cá hồi băng | Hồ (lỗ băng) | Đông | 08:00–17:00 | Mọi | 3 | 220 | 18 |
| Cá thu | Biển | Xuân, Hạ | 06:00–18:00 | Nắng | 3 | 140 | 14 |
| Cá ngừ | Biển | Hạ | 08:00–16:00 | Nắng | 4 | 260 | 20 |
| Mực ống | Biển | Thu, Đông | 20:00–02:00 | Mọi | 3 | 160 | 15 |
| Cá chình | Sông | Thu | 20:00–02:00 | Mưa | 4 | 280 | 22 |
| Cá mặt trăng | Biển | Đông | 22:00–02:00, đêm Trăng Tròn | Quang | 5 | 600 | 40 |
| **Cá Sao** (huyền thoại) | Thác nước | Mọi mùa | Đêm có mưa sao băng | Quang | 5 | 1.200 | 70 |
| **Rồng Sương** (huyền thoại) | Hồ Gương | Thu | 05:00–09:00, khi Sương Quên | Sương mù | 5 | 1.500 | 80 |

**Bẫy cua / bẫy cá:** đặt ở mép nước, mồi nhử, kiểm tra mỗi sáng. Cho cua, tôm, sò (giá 40–120).

---

## 14. Màn hình và luồng giao diện

### 14.1 Sơ đồ luồng

```
Boot → Splash (logo) → Màn hình Tiêu đề
                          ├─ Tiếp tục → Tải save → Map cuối cùng
                          ├─ Trò chơi mới → Tạo nhân vật → Thú cưng/Môn yêu thích → Cutscene mở đầu → Nông trại (Xuân 1, 06:00)
                          ├─ Tải game (3 ô)
                          ├─ Phòng học (ôn luyện, không cần save)
                          ├─ Cài đặt
                          └─ Thoát

Trong game:  Playing ⇄ Menu / Hội thoại / Mini-game / Cutscene / Tổng kết ngày / Màn hình ngất
```

### 14.2 Màn hình Tiêu đề (màn hình bắt đầu)

- **Phông nền:** toàn cảnh làng 4 lớp parallax (sao – núi – đồi – làng). Cảnh phản ánh **mùa, giờ, thời tiết của bản lưu gần nhất**; chưa có save thì là bình minh mùa Xuân.
- **Hoạt động nền:** khói ống khói, chim bay, mây trôi, đom đóm vào đêm, tuyết/mưa rơi theo thời tiết; ngôi sao nhỏ nhấp nháy tượng trưng cho Ngôi Sao Tri Thức.
- **Logo** "Làng Sao Mai" pixel ở trên-giữa; menu dọc ở trái-giữa: Tiếp tục, Trò chơi mới, Tải game, Phòng học, Cài đặt, Thoát. Con trỏ là Sổ Tay nhỏ.
- **Ô tải game (3 ô):** tên nhân vật, tên nông trại, ngày-mùa-năm, giờ chơi, ảnh chụp cảnh lúc lưu.
- **Nhạc:** giai điệu piano nhẹ + sáo; âm nền chim và gió.

### 14.3 Tạo nhân vật và cảnh mở đầu

1. **Tạo nhân vật** (7.1): xem trước 4 hướng, hoạt ảnh đi/đứng.
2. **Chọn thú cưng và môn yêu thích.**
3. **Cutscene mở đầu (\~90 giây, có thể bỏ qua):** xe buýt đến làng lúc sáng sớm, cảnh trượt qua các khu vực, người chơi đến cổng nông trại; Dì Năm đưa chìa khóa và lá thư; con thú cưng chạy ra.
4. Vào nông trại 06:00 ngày 1 mùa Xuân; hướng dẫn nhẹ bằng gợi ý trên màn hình, không khóa điều khiển.

### 14.4 Mỗi khu vực một chủ đề riêng (bố cục, bảng màu, âm thanh)

| Màn hình / map | Bố cục và hướng đi | Bảng màu chủ đạo | Nhạc và âm thanh | Cảm giác |
| --- | --- | --- | --- | --- |
| Nông Trại | Mở, lối ra ở 4 hướng, trung tâm là khu đất canh tác | Xanh lá, nâu đất, ấm | Guitar mộc, tiếng gà, gió | Bình yên, của riêng mình |
| Đồng Cỏ | Thảo nguyên rộng, rào gỗ | Xanh nhạt, vàng nắng | Sáo, bê kêu | Thư thái |
| Phố Chợ | Hẹp, dài, cửa hàng hai bên | Cam ấm, đỏ gạch | Jazz nhẹ, tiếng rao | Nhộn nhịp |
| Quảng Trường | Đối xứng, đài phun nước ở giữa | Xám be, hoa nhiều màu | Accordion, tiếng người | Cộng đồng |
| Trường Ánh Dương | Dạng chữ U, sân trước, vườn sau | Vàng chanh, xanh dương | Xylophone vui | Tươi vui, ham học |
| Đồi Thư Viện | Dốc nhẹ lên đỉnh, vườn đọc | Nâu vàng, xanh rêu | Piano + cello, lá xào xạc | Tĩnh lặng, suy tư |
| Rừng Thì Thầm | Mê cung lối mòn, ánh sáng lọt tán | Xanh thẫm, tím đêm | Sáo thì thầm; đêm: bass trầm | Huyền bí, lo âu nhẹ |
| Hầm Đá | Tầng ngang, hang động quanh co | Xám xanh, lam, đỏ lửa nhỏ | Nhỏ giọt, synth u trầm | Căng thẳng, tò mò |
| Hồ Gương & Sông | Nước ở giữa, bờ vòng quanh | Xanh lam bạc | Đàn hạc, tiếng nước | Thiền, chậm |
| Bãi Biển | Dải dài ngang, bến cảng bên phải | Xanh ngọc, vàng cát | Ukulele, sóng | Nghỉ ngơi, phiêu lưu |
| Núi Mây | Lên dọc theo nhiều tầng | Trắng, xanh lạnh, tím | Dàn dây rộng, gió | Hùng vĩ, cô độc |

### 14.5 Các màn hình phụ

| Màn hình | Kích hoạt | Bố cục và thông tin | Hành động |
| --- | --- | --- | --- |
| Hội thoại | Nói chuyện NPC | Hộp ở đáy, chân dung 48×48 bên trái, tên NPC, văn bản hiện từng chữ, lựa chọn 2–4 dòng | Phím E tiếp, số chọn, Esc đóng |
| Cửa hàng | Mở Shop | Hai cột: Hàng của tiệm / Túi đồ; tổng tiền dưới đáy | Kéo, Enter mua/bán, giữ Shift mua cả chồng |
| Tổng kết ngày | Ngủ hoặc ngất | Danh sách: Xu kiếm, vật bán, XP nhận, nhiệm vụ xong, kỹ năng/tri thức lên cấp, mất mát (nếu ngất), dự báo thời tiết mai, ảnh cảnh hoàng hôn | Nút Tiếp tục → tự động lưu → sáng hôm sau 06:00 |
| Màn hình ngất | HP = 0 hoặc 02:00 | Mờ dần đen, dòng chữ lý do, mất mát ngắn gọn | Tự chuyển sang tổng kết |
| Mini-game học | Bàn học, lớp học, câu đố | Khung riêng giữa màn hình, đề bài lớn, bộ đếm lượt, nút Gợi ý/Bỏ qua | Trả lời, xem giải thích, nhận sao |
| Bản đồ | Phím M | Bản đồ làng, đánh dấu vị trí, NPC theo lịch (nếu mở khóa Tri thức Ký) | Chọn điểm để ghim nhiệm vụ |
| Cutscene | Sự kiện tim, cốt truyện | Letterbox đen trên dưới, hội thoại, camera di chuyển | Bỏ qua bằng giữ Esc |

---

## 15. Kiến trúc kỹ thuật và lộ trình thực hiện

### 15.1 Cây node chuẩn của Player

```
Player (CharacterBody2D)
├── Visuals (Node2D)
│   ├── ShadowSprite, BodySprite, BottomSprite, ShoesSprite, TopSprite,
│   │   EyesSprite, HairSprite, HatSprite, AccessorySprite
│   └── HandItem (Node2D)
├── CollisionShape2D            # chỉ phần chân
├── AnimationPlayer             # điều khiển frame của mọi lớp
├── StateMachine                # Idle, Walk, Run, UseTool, Attack, Roll, Hurt, Faint...
├── HealthComponent
├── StaminaComponent
├── InventoryComponent
├── EquipmentComponent
├── InteractionDetector (Area2D)
├── Hurtbox (Area2D)
├── Hitbox (Area2D)             # bật theo khung hoạt ảnh tấn công
└── Camera2D
```

### 15.2 Tín hiệu mẫu trên `EventBus`

`item_added(item_id, amount)`, `item_used(item_id)`, `tool_used(tool_id, target_cell)`, `crop_harvested(crop_id, quality)`, `monster_killed(monster_id, tier)`, `quest_state_changed(quest_id, state)`, `knowledge_session_finished(subject, stars)`, `day_started(day_index)`, `season_changed(season_index)`, `weather_changed(weather_id)`, `map_entered(map_id)`, `npc_gift_given(npc_id, item_id)`, `player_leveled_up(new_level)`.

### 15.3 Dữ liệu lưu game (`save_version` bắt buộc)

| Khóa | Nội dung |
| --- | --- |
| `meta` | Phiên bản, tên, tên nông trại, ngày giờ chơi, thời gian chơi |
| `clock` | `total_game_minutes`, ngày, mùa, năm, `world_seed` |
| `player` | Vị trí, map, HP, thể lực, XP, cấp, kỹ năng, tri thức, trang bị |
| `inventory` | Túi, hotbar, rương (mỗi rương theo `persistent_id`) |
| `maps` | Trạng thái từng map: ô đất, cây, vật đặt, thú nuôi, vật rơi |
| `quests` | Trạng thái và tiến độ từng nhiệm vụ |
| `npcs` | Tim hữu nghị, quà đã tặng, sự kiện đã xem |
| `knowledge` | Cấp bậc, lịch sử câu hỏi, hộp Leitner |
| `flags` | Cờ cốt truyện, mở khóa, bách khoa |

### 15.4 Hiệu năng

- Map lớn chia **chunk**; chỉ cập nhật thực thể trong bán kính 2 màn hình quanh camera.
- Thực vật ngoài tầm nhìn chỉ cập nhật **theo ngày**, không chạy mỗi khung.
- Dùng **object pooling** cho vật rơi, hạt hiệu ứng, đạn.
- Mục tiêu: 60 FPS, dưới 300 MB RAM, nạp map dưới 1 giây trên máy phổ thông.

### 15.5 Lộ trình các cột mốc

| Cột mốc | Nội dung | Tiêu chí hoàn thành |
| --- | --- | --- |
| M0 | Dựng dự án, cấu trúc folder, autoload rỗng, pixel-perfect, CI/test | Chạy cảnh trống ở 320×180 scale nguyên |
| M1 | Player di chuyển, hoạt ảnh ghép lớp, tilemap, camera, Y-sort | Đi vòng nông trại mẫu không lỗi chồng lớp |
| M2 | `GameClock`, ánh sáng theo giờ, mùa, `WeatherSystem` có seed và dự báo | Chạy 1 ngày game trong 240 phút thực (có nút tua nhanh khi dev) |
| M3 | `ItemData`, túi đồ, hotbar, rương, UI Menu | Kéo thả, chồng, cất/lấy ổn định, lưu/tải được |
| M4 | Vòng lặp nông nghiệp: đất, tưới, cây trồng, thu hoạch, bán | Trồng–thu–bán trọn vẹn qua 3 ngày |
| M5 | `Interactable`, `MapPortal`, công trình nội/ngoại thất, `SceneManager` | Vào/ra mọi công trình, trạng thái giữ nguyên |
| M6 | NPC, lịch sinh hoạt, Dialogue Manager, Shop, hữu nghị | NPC đi theo lịch, mưa đổi lịch |
| M7 | `QuestManager`, nhật ký, theo dõi, 8 loại nhiệm vụ | Hoàn thành 1 nhiệm vụ mỗi loại từ đầu đến cuối |
| M8 | Chiến đấu, quái, `SpawnDirector`, Hầm Đá, rơi vật phẩm | 5 loại quái hoạt động, XP và drop đúng bảng |
| M9 | Động vật nuôi, công trình, chăm sóc, sản phẩm | Nuôi gà–bò qua 7 ngày, chất lượng theo hạnh phúc |
| M10 | Nước, câu cá, thủy triều, bẫy | Câu mọi loại cá theo điều kiện |
| M11 | `KnowledgeManager`, ngân hàng câu hỏi, 5 mảng mini-game, Phòng học | Thêm câu hỏi mới chỉ bằng JSON, độ khó thích ứng chạy đúng |
| M12 | Nội dung cốt truyện chương 0–7, 5 Bóng Quên, lễ hội | Chơi trọn vẹn 1 năm game |
| M13 | Âm thanh, hiệu ứng, cân bằng, trợ năng, di trú save | Qua bài test cân bằng và 60 FPS |
| M14 | Thử nghiệm kín, sửa lỗi, đóng gói | Bản build ổn định cho Windows |

### 15.6 Mẫu "Nhiệm vụ hiện tại" để điền vào Master Prompt

- *"Làm M2: viết `GameClock` autoload theo mục 4.1, tín hiệu `minute_changed`, `hour_changed`, `day_started`; thêm `WeatherSystem` sinh thời tiết có seed theo 4.4 và dự báo ngày mai; kèm scene test hiển thị giờ và thời tiết, và unit test GUT cho công thức chuyển đổi thời gian."*
- *"Làm M4 phần đất canh tác: `SoilTile` có các trạng thái ở mục 5.3 (cỏ, cuốc, tưới, bón, gieo), `Plant` đọc `CropData` theo bảng 12.3, tưới lúc mưa tự động, héo khi đổi mùa."*
- *"Làm M11 phần ngân hàng câu hỏi: nạp JSON theo schema 9.4, chọn câu theo bậc khó thích ứng và hộp Leitner, trả về 5 câu cho một phiên học."*

---

## 16. Phụ lục

### 16.1 Danh sách asset tối thiểu để bắt đầu (MVP)

| Nhóm | Số lượng gợi ý |
| --- | --- |
| Tileset ngoài trời (4 mùa) | 4 bộ × (cỏ, đất, đường, nước, cây, đá) |
| Tileset nội thất | 1 bộ chung (sàn, tường, đồ nội thất cơ bản) |
| Nhân vật | 1 body × 2 kiểu, 6 tóc, 6 áo, 4 quần, 3 giày, 3 mũ |
| NPC | 12 sprite 16×32 + 12 chân dung 48×48 |
| Công cụ và vũ khí | 6 công cụ × 5 bậc, 3 vũ khí × 5 bậc |
| Cây trồng | 14 loại × 5 khung |
| Động vật | Gà, bò (4 hướng, 3 trạng thái) trước, các loài khác sau |
| Quái | 6 loại đầu (Slime Mực, Sâu Đá, Dơi Giấy, Nấm Độc, Cua Đá, Sói) |
| UI | Khung, nút, thanh HP/thể lực, hotbar, icon vật phẩm 16×16 |
| Âm thanh | 11 nhạc nền theo map, 40 hiệu ứng, 6 âm nền (mưa, gió, sóng...) |

### 16.2 Các điểm cần bạn xác nhận trước khi bắt đầu code

1. **Độ dài mùa:** 7 ngày/mùa là phù hợp khi 1 ngày game dài 240 phút thực; nếu muốn mùa dài hơn thì chỉ sửa hằng số `DAYS_PER_SEASON` và dãn cốt truyện tương ứng.
2. **Bản quyền asset:** chọn gói asset cụ thể để chốt kích thước khung hoạt ảnh nhân vật (16×32 là giả định).
3. **Nền tảng:** PC là mặc định; nếu nhắm mobile cần thêm điều khiển cảm ứng và giảm kích thước map.
4. **Ngôn ngữ nội dung học tập:** khối lượng ngân hàng câu hỏi ban đầu (đề xuất 50 câu mỗi môn cho bản MVP).
