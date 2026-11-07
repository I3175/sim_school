extends Control

const ART := "res://assets/art/sao_mai/ui/"
const INK := Color("#2B1B17")
const WOOD := Color("#5A3A2A")
const PAPER := Color("#F4E4BC")
const CREAM := Color("#FFF6DA")
const GOLD := Color("#F2C14E")
const GREEN := Color("#6DB04A")
const DARK_GREEN := Color("#3E7B3A")
const RED := Color("#D94A4A")
const DARK_RED := Color("#8E2D3A")
const BLUE := Color("#4A86C5")
const PURPLE := Color("#8A64B8")
const ORANGE := Color("#E8884A")
const DIGITS := preload("res://assets/art/sao_mai/ui/sao-mai-digits.fnt")
const FONTS := {
	8: preload("res://assets/art/sao_mai/ui/sao-mai-8.fnt"),
	10: preload("res://assets/art/sao_mai/ui/sao-mai-10.fnt"),
	12: preload("res://assets/art/sao_mai/ui/sao-mai-12.fnt"),
}
const PAGES := ["title", "hud", "inventory", "equipment", "skills", "quests", "codex", "map",
	"relationships", "crafting", "settings", "dialogue", "shop", "learning", "fishing",
	"combat", "summary", "saves", "create", "cutscene", "widgets"]
const TABS := ["Túi đồ", "Trang bị", "Kỹ năng", "Nhiệm vụ", "Bách khoa", "Bản đồ",
	"Quan hệ", "Chế tạo", "Cài đặt", "Thoát"]
const TAB_ICONS := ["bag", "sword", "spark", "letter", "book", "map", "heart", "gear", "gear", "lock"]
const ITEMS := ["hoe", "watering_can", "seed_greens", "crop_greens", "stone", "wood"]
const TOPIC_NAMES := ["Số", "Chữ", "Ngữ", "Vật", "Ký"]
const TOPIC_ICONS := ["calculator", "pen", "dialogue", "flask", "history"]
const TOPIC_COLORS := [BLUE, ORANGE, PURPLE, DARK_GREEN, Color("#9C6D20")]
const QUESTIONS := ["Trắc nghiệm", "Điền từ", "Xếp thứ tự", "Nối cặp",
	"Nhập số", "Phân loại", "Lưới ô"]

var page_index := 0
var hotbar_index := 0
var question_index := 0
var text_size := 8
var selected_answer := -1
var world: Control
var initial_focus: Button
var gallery_snapshot := false

func _ready() -> void:
	var shot := ""
	var shot_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gallery-page="):
			page_index = maxi(0, PAGES.find(arg.trim_prefix("--gallery-page=")))
		elif arg.begins_with("--gallery-shot="):
			shot = arg.trim_prefix("--gallery-shot=")
		elif arg.begins_with("--gallery-shot-dir="):
			shot_dir = arg.trim_prefix("--gallery-shot-dir=")
	gallery_snapshot = not shot.is_empty() or not shot_dir.is_empty()
	_show_page()
	if not shot_dir.is_empty():
		for index in PAGES.size():
			page_index = index
			_show_page()
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var path := shot_dir.path_join(PAGES[index] + ".png")
			var result := get_viewport().get_texture().get_image().save_png(path)
			if result != OK:
				get_tree().quit(result)
				return
		get_tree().quit()
	elif not shot.is_empty():
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var result := get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit(result)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_page_down") or _shoulder(event, JOY_BUTTON_RIGHT_SHOULDER):
		_step(1)
	elif event.is_action_pressed("ui_page_up") or _shoulder(event, JOY_BUTTON_LEFT_SHOULDER):
		_step(-1)
	elif event.is_action_pressed("ui_cancel"):
		_open("title")
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_open("widgets")
		elif PAGES[page_index] == "hud":
			var hotbar_keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL]
			var slot := hotbar_keys.find(event.keycode)
			if slot >= 0:
				_select_slot(slot)

func _shoulder(event: InputEvent, index: JoyButton) -> bool:
	return event is InputEventJoypadButton and event.pressed and event.button_index == index

func _step(direction: int) -> void:
	page_index = posmod(page_index + direction, PAGES.size())
	_show_page()

func _open(page: String) -> void:
	page_index = PAGES.find(page)
	_show_page()

func _show_page() -> void:
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	world = Control.new()
	world.size = Vector2(320, 180)
	add_child(world)
	initial_focus = null
	var page: String = PAGES[page_index]
	match page:
		"title": _title()
		"hud": _farm(); _hud()
		"dialogue", "cutscene": _dialogue(page == "cutscene")
		"shop": _shop()
		"learning": _learning()
		"fishing": _fishing()
		"combat": _combat()
		"summary": _summary()
		"saves": _saves()
		"create": _create_character()
		"widgets": _widgets()
		_: _journal(page)
	if not gallery_snapshot:
		_nav_controls()
	if is_instance_valid(initial_focus):
		initial_focus.grab_focus()

func _place(control: Control, x: int, y: int, w: int, h: int) -> void:
	world.add_child(control)
	control.position = Vector2(x, y)
	control.size = Vector2(w, h)

func _panel(style: String, x: int, y: int, w: int, h: int) -> Panel:
	var panel := Panel.new()
	panel.theme_type_variation = StringName(style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(panel, x, y, w, h)
	return panel

func _fill(color: Color, x: int, y: int, w: int, h: int) -> void:
	var area := ColorRect.new()
	area.color = color
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(area, x, y, w, h)

func _label(value: String, x: int, y: int, w: int, h: int, color := CREAM,
		font_size := 8, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	if FONTS.has(font_size):
		label.add_theme_font_override("font", FONTS[font_size])
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(label, x, y, w, h)
	return label

func _digits(value: String, x: int, y: int, w: int, h: int, color := CREAM) -> void:
	var label := _label(value, x, y, w, h, color, 7, HORIZONTAL_ALIGNMENT_RIGHT)
	label.add_theme_font_override("font", DIGITS)

func _pic(path: String, x: int, y: int, w: int, h: int) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = load(path) as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(picture, x, y, w, h)
	return picture

func _icon(name: String, x: int, y: int, side := 8) -> void:
	_pic(ART + name + ".png", x, y, side, side)

func _button(value: String, x: int, y: int, w: int, h: int, action: Callable,
		focus := false, disabled := false) -> Button:
	var button := Button.new()
	button.text = value
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.disabled = disabled
	button.pressed.connect(action)
	_place(button, x, y, w, h)
	if focus:
		initial_focus = button
	return button

func _bar(x: int, y: int, w: int, h: int, fraction: float, fill: Color, track: Color) -> void:
	_fill(INK, x, y, w, h)
	_fill(track, x + 1, y + 1, w - 2, h - 2)
	_fill(fill, x + 1, y + 1, roundi((w - 2) * fraction), h - 2)

func _slot(x: int, y: int, item: int, chosen := false, count := 0) -> void:
	_panel("SlotPanel", x, y, 20, 20)
	if chosen:
		_fill(GOLD, x + 1, y, 18, 1)
		_fill(GOLD, x, y + 1, 1, 18)
		_fill(GOLD, x + 19, y + 1, 1, 18)
		_fill(GOLD, x + 1, y + 19, 18, 1)
	if item >= 0:
		_pic("res://assets/art/sao_mai/items/" + ITEMS[item] + ".png", x + 2, y + 2, 16, 16)
	if count > 0:
		_digits(str(count), x + 3, y + 11, 15, 8)

func _nav_controls() -> void:
	var previous := _button("←", 128, 1, 16, 13, func() -> void: _step(-1))
	previous.tooltip_text = "Màn trước (Page Up / LB)"
	var following := _button("→", 176, 1, 16, 13, func() -> void: _step(1))
	following.tooltip_text = "Màn sau (Page Down / RB)"
	_digits("%02d/%02d" % [page_index + 1, PAGES.size()], 145, 3, 29, 9)

func _title() -> void:
	_pic(ART + "title.png", 0, 0, 320, 180)
	_panel("WoodPanel", 85, 13, 150, 38)
	_icon("spark", 155, 17)
	_label("LÀNG SAO MAI", 89, 24, 142, 15, CREAM, 12, HORIZONTAL_ALIGNMENT_CENTER)
	_label("Sổ Tay Tri Thức", 89, 38, 142, 12, GOLD, 8, HORIZONTAL_ALIGNMENT_CENTER)
	var entries := ["Tiếp tục", "Trò chơi mới", "Tải game", "Phòng học", "Cài đặt", "Thoát"]
	var targets := ["hud", "create", "saves", "learning", "settings"]
	var marker := _pic(ART + "book.png", 14, 76, 8, 8)
	for index in entries.size():
		var action := _confirm_exit if index == entries.size() - 1 else _open.bind(targets[index])
		var menu_button := _button(entries[index], 24, 72 + index * 17, 87, 16, action, index == 0)
		menu_button.focus_entered.connect(func() -> void: marker.position.y = 76 + index * 17)
	_label("UI Gallery · 0.1", 8, 167, 92, 12)

func _farm() -> void:
	_pic(ART + "farm-preview.png", 0, 0, 320, 180)
	_player_sprite(152, 58)

func _player_sprite(x: int, y: int, zoom := 1) -> void:
	var layers := ["shadow", "body", "bottom", "shoes", "top", "eyes", "hair"]
	for name in layers:
		var frame := AtlasTexture.new()
		frame.atlas = load("res://assets/art/characters/prototype/" + name + ".svg") as Texture2D
		frame.region = Rect2(0, 0, 16, 32)
		var sprite := TextureRect.new()
		sprite.texture = frame
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(sprite, x, y, 16 * zoom, 32 * zoom)

func _hud() -> void:
	_panel("WoodPanel", 4, 4, 112, 33)
	_icon("letter", 8, 9)
	_label("Vụ mùa đầu tiên", 20, 6, 92, 14, GOLD)
	_label("Thu 3 cải xanh  (1/3)", 8, 21, 103, 12)
	_panel("WoodPanel", 240, 4, 76, 42)
	_icon("sun", 244, 9, 16)
	_digits("08:40", 262, 7, 29, 11)
	_label("Thứ Hai", 244, 21, 39, 12)
	_icon("cloud", 283, 24)
	_label("22°C", 291, 21, 23, 12, GREEN)
	_label("Xuân · Ngày 3", 244, 32, 71, 12)
	_panel("WoodPanel", 240, 48, 76, 14)
	_icon("coin", 244, 51)
	_digits("240", 260, 50, 51, 10)
	_panel("WoodPanel", 266, 66, 48, 48)
	_pic(ART + "farm-minimap.png", 268, 70, 44, 38)
	_fill(CREAM, 289, 87, 2, 2)
	_icon("bolt", 308, 118)
	_panel("SlotPanel", 308, 128, 8, 44)
	_fill(DARK_GREEN, 310, 130, 4, 40)
	_fill(GREEN, 310, 140, 4, 30)
	_panel("WoodPanel", 4, 156, 34, 20)
	_icon("heart", 5, 159)
	_bar(13, 159, 24, 6, 0.8, RED, DARK_RED)
	_digits("80/100", 5, 167, 32, 8)
	for i in 12:
		var slot_y := 154 if i == hotbar_index else 156
		_slot(40 + 20 * i, slot_y, i if i < ITEMS.size() else -1, i == hotbar_index,
			[0, 0, 12, 3, 8, 6][i] if i < ITEMS.size() else 0)
		_label("1234567890-=".substr(i, 1), 42 + 20 * i, slot_y, 8, 9, PAPER, 7)

func _journal(page: String) -> void:
	_farm()
	_fill(Color(0.10, 0.065, 0.055, 0.60), 0, 0, 320, 180)
	_panel("WoodPanel", 6, 6, 308, 168)
	_panel("PaperPanel", 28, 10, 278, 158)
	var selected := PAGES.find(page) - 2
	for i in TABS.size():
		var tab := _button("", 7, 10 + 16 * i, 20, 16, _tab.bind(i), i == selected)
		tab.tooltip_text = TABS[i]
		if i == selected:
			_fill(GOLD, 8, 11 + 16 * i, 2, 14)
		_icon(TAB_ICONS[i], 11, 10 + 16 * i, 16)
	_label(TABS[selected], 34, 11, 248, 14, INK, 10)
	_fill(WOOD, 34, 25, 266, 1)
	match page:
		"inventory": _inventory()
		"equipment": _equipment()
		"skills": _skills()
		"quests": _quests()
		"codex": _codex()
		"map": _world_map()
		"relationships": _relationships()
		"crafting": _crafting()
		"settings": _settings()

func _tab(index: int) -> void:
	if index == 9:
		_confirm_exit()
	else:
		_open(PAGES[index + 2])

func _confirm_exit() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Thoát Gallery"
	dialog.dialog_text = "Đóng bản duyệt giao diện?"
	dialog.ok_button_text = "Thoát"
	dialog.cancel_button_text = "Hủy"
	dialog.confirmed.connect(get_tree().quit)
	dialog.visibility_changed.connect(func() -> void:
		if not dialog.visible:
			dialog.queue_free())
	world.add_child(dialog)
	dialog.popup_centered(Vector2i(172, 70))
	dialog.get_cancel_button().grab_focus()

func _inventory() -> void:
	for row in 3:
		for col in 12:
			_slot(34 + 20 * col, 28 + 20 * row, col if row == 0 and col < ITEMS.size() else -1,
				row == 0 and col == hotbar_index, 12 if row == 0 and col == 2 else 0)
	_button("Sắp xếp", 34, 91, 54, 15, func() -> void: _select_slot(0))
	_button("Chọn ô kế", 92, 91, 65, 15, func() -> void: _select_slot((hotbar_index + 1) % 12))
	_icon("coin", 237, 94)
	_digits("240", 253, 92, 23, 13, INK)
	_panel("WoodPanel", 34, 110, 266, 53)
	_slot(40, 120, hotbar_index if hotbar_index < ITEMS.size() else -1, true)
	var names := ["Cuốc gỗ", "Bình tưới", "Hạt cải", "Cải xanh", "Đá", "Gỗ"]
	_label(names[hotbar_index] if hotbar_index < names.size() else "Ô trống", 67, 113, 220, 14, GOLD, 10)
	_label("Vật dụng nông trại · Thường", 67, 129, 220, 12)
	_label("Kéo vào ô trống để đổi chỗ", 67, 141, 220, 12)

func _select_slot(index: int) -> void:
	hotbar_index = index
	_show_page()

func _equipment() -> void:
	_panel("WoodPanel", 39, 35, 116, 113)
	_player_sprite(80, 48, 2)
	for row in 3:
		_slot(46, 45 + row * 30, -1)
		_slot(126, 45 + row * 30, -1)
	_label("Bộ trang bị  2/3", 165, 35, 131, 16, INK, 10)
	var names := ["HP", "Thể lực", "Tấn công", "Phòng thủ", "Tốc độ", "May mắn", "Hút đồ", "Chí mạng"]
	var values := ["100", "80", "12", "6", "96", "4", "20", "5%"]
	for i in names.size():
		_label(names[i], 165, 53 + i * 12, 90, 12, INK)
		_digits(values[i], 255, 53 + i * 12, 36, 12, INK)
	_button("Ẩn mũ", 66, 128, 60, 16, func() -> void: pass)

func _skills() -> void:
	for i in 5:
		_icon(TOPIC_ICONS[i], 40, 35 + 21 * i, 12)
		_label(TOPIC_NAMES[i] + " · Cấp " + str(2 + i % 3), 58, 34 + 21 * i, 90, 13, INK)
		_bar(58, 47 + 21 * i, 80, 5, (i + 3) * 0.10, TOPIC_COLORS[i], WOOD)
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([Vector2(222, 54), Vector2(256, 78), Vector2(244, 118),
		Vector2(200, 118), Vector2(187, 78)])
	polygon.color = Color("#D6BB91")
	world.add_child(polygon)
	var stats := Polygon2D.new()
	stats.polygon = PackedVector2Array([Vector2(222, 69), Vector2(245, 82), Vector2(235, 101),
		Vector2(206, 110), Vector2(197, 82)])
	stats.color = Color("#8A64B8B5")
	world.add_child(stats)
	for i in 5:
		_icon(TOPIC_ICONS[i], [218, 259, 244, 189, 177][i], [39, 72, 123, 123, 72][i])
	_label("Điểm còn: 2", 178, 146, 92, 12, INK)

func _quests() -> void:
	for i in 4:
		var chip: String = ["Hôm nay", "Chính", "Phụ", "Đã xong"][i]
		_button(chip, 36 + 64 * i, 29, 60, 15, func() -> void: pass)
	_panel("WoodPanel", 36, 48, 103, 112)
	_label("!  Vụ mùa đầu tiên", 41, 52, 93, 16, GOLD)
	_label("?  Thư viện mở cửa", 41, 70, 93, 16)
	_label("✓  Lời chào đầu", 41, 88, 93, 16)
	_label("Vụ mùa đầu tiên", 148, 52, 144, 16, INK, 10)
	_label("Người giao · Dì Năm", 148, 72, 144, 12, INK)
	_label("Thu 3 cải xanh (1/3)", 148, 91, 144, 12, DARK_GREEN)
	_icon("spark", 148, 114)
	_label("50 / 75 / 100 Xu", 161, 112, 130, 12, INK)
	_button("Ghim nhiệm vụ", 148, 139, 87, 16, func() -> void: pass)

func _codex() -> void:
	_label("Cá    Thú    Quái    Cây    Khoáng sản", 38, 29, 249, 15, INK)
	for row in 4:
		for col in 8:
			var x := 38 + col * 21
			var y := 48 + row * 22
			_slot(x, y, -1, row == 0 and col == 0)
			if row == 0 and col < 3:
				_icon("fish", x + 4, y + 4, 12)
			else:
				_label("?", x, y, 20, 20, WOOD, 8, HORIZONTAL_ALIGNMENT_CENTER)
	_icon("fish", 227, 51, 48)
	_label("Cá chép", 211, 100, 81, 16, INK, 10, HORIZONTAL_ALIGNMENT_CENTER)
	_label("Hồ Gương", 211, 119, 81, 14, INK, 8, HORIZONTAL_ALIGNMENT_CENTER)
	_digits("3/40", 236, 144, 35, 11, INK)

func _world_map() -> void:
	_panel("PaperPanel", 37, 30, 259, 129)
	var nodes := {"farm": Vector2i(48, 110), "ranch": Vector2i(47, 134), "market": Vector2i(103, 108),
		"square": Vector2i(157, 103), "school": Vector2i(221, 118), "library": Vector2i(157, 67),
		"forest": Vector2i(92, 59), "mine": Vector2i(53, 71), "lake": Vector2i(220, 67),
		"beach": Vector2i(256, 94), "mountain": Vector2i(157, 39)}
	var links := [["farm","ranch"], ["farm","market"], ["market","square"], ["square","school"],
		["square","library"], ["square","beach"], ["library","forest"], ["forest","mine"],
		["library","lake"], ["lake","beach"], ["library","mountain"]]
	for link in links:
		var trail := Line2D.new()
		trail.width = 2.0
		trail.default_color = Color("#B98554")
		trail.points = PackedVector2Array([nodes[link[0]] + Vector2i(4, 4), nodes[link[1]] + Vector2i(4, 4)])
		world.add_child(trail)
	var titles := {"farm":"Nông trại", "ranch":"Đồng Cỏ", "market":"Phố Chợ", "square":"Quảng trường",
		"school":"Trường Ánh Dương", "library":"Đồi Thư Viện", "forest":"Rừng Thì Thầm", "mine":"Hầm Đá",
		"lake":"Hồ Gương", "beach":"Bãi Biển", "mountain":"Núi Mây"}
	for key: String in nodes:
		var spot: Vector2i = nodes[key]
		var locked := key in ["forest", "mine", "beach", "mountain"]
		_icon("lock" if locked else "spark" if key == "farm" else "leaf", spot.x, spot.y)
		var label_x := maxi(39, spot.x - 18)
		_label(titles[key], label_x, spot.y + 8, mini(90, 295 - label_x), 12, INK)
	_label("★ Vị trí của bạn", 206, 143, 86, 12, DARK_GREEN)

func _relationships() -> void:
	_pic(ART + "di_nam.png", 43, 41, 48, 48)
	_label("Dì Năm", 105, 40, 160, 16, INK, 10)
	for i in 10:
		_icon("heart", 105 + i * 11, 61, 8)
		if i > 2:
			_fill(Color(PAPER, 0.72), 105 + i * 11, 61, 8, 8)
	_label("Tiệm tạp hóa · Phố Chợ", 105, 74, 160, 12, INK)
	_fill(WOOD, 40, 99, 250, 1)
	_label("Yêu: Cải xanh", 40, 106, 115, 14, INK)
	_label("Thích: ?", 40, 122, 115, 14, INK)
	_label("Quà hôm nay · Chưa tặng", 156, 106, 132, 14, INK)

func _crafting() -> void:
	_panel("WoodPanel", 37, 34, 100, 125)
	_label("Bàn chế tạo", 43, 39, 90, 14, GOLD)
	_label("Hòm gỗ", 43, 62, 90, 14)
	_label("Hàng rào", 43, 80, 90, 14)
	_label("???", 43, 98, 90, 14)
	_label("Hòm gỗ", 148, 38, 144, 16, INK, 10)
	_slot(148, 60, 5, true, 6)
	_label("Gỗ  6/10", 177, 64, 110, 12, DARK_RED)
	_label("Thời gian: 10 phút", 148, 94, 144, 13, INK)
	_button("Chế tạo ×1", 148, 136, 80, 18, func() -> void: pass, false, true)

func _settings() -> void:
	_label("Hiển thị và trợ năng", 38, 29, 232, 15, INK, 10)
	for i in 3:
		var size_px: int = [8, 10, 12][i]
		_button(str(size_px) + " px", 38 + i * 51, 50, 46, 16, _set_text_size.bind(size_px))
	if text_size == 12:
		_panel("PaperPanel", 38, 75, 254, 58)
		_label("Đã mở: Đồi Thư Viện", 44, 79, 238, 18, INK, text_size)
		_label("Giảm nhấp nháy", 44, 104, 238, 18, INK, text_size)
	elif text_size == 10:
		_panel("PaperPanel", 38, 75, 240, 57)
		_label("Đã mở: Đồi Thư Viện", 44, 79, 227, 16, INK, text_size)
		_label("Giảm nhấp nháy", 44, 95, 227, 16, INK, text_size)
		_label("Vùng an toàn TV", 44, 111, 227, 16, INK, text_size)
	else:
		_panel("PaperPanel", 38, 75, 222, 49)
		_label("Đã mở: Đồi Thư Viện", 44, 78, 207, 14, INK, text_size)
		_label("Giảm nhấp nháy", 44, 92, 207, 14, INK, text_size)
		_label("Vùng an toàn TV", 44, 106, 207, 14, INK, text_size)
	_button("Xem mẫu widget", 38, 140, 104, 18, _open.bind("widgets"))

func _set_text_size(value: int) -> void:
	text_size = value
	_show_page()

func _dialogue(cutscene: bool) -> void:
	_farm()
	if cutscene:
		_fill(INK, 0, 0, 320, 20)
		_fill(INK, 0, 160, 320, 20)
		_label("Ngày đầu ở Nông trại Mầm Xanh", 30, 3, 260, 14, CREAM, 8, HORIZONTAL_ALIGNMENT_CENTER)
	_panel("WoodPanel", 8, 118, 304, 56)
	_panel("PaperPanel", 10, 120, 52, 52)
	_pic(ART + "di_nam.png", 12, 122, 48, 48)
	_panel("WoodPanel", 64, 106, 64, 13)
	_label("Dì Năm", 68, 107, 56, 12, GOLD)
	_label("Mừng cháu về Làng Sao Mai!", 68, 123, 232, 12)
	_label("Dì giữ chìa khóa và lá thư này cho cháu.", 68, 135, 232, 12)
	_label("Mai mình gieo mẻ hạt đầu tiên nhé.", 68, 147, 232, 12)
	_icon("heart", 291, 159)
	_button("1  Cháu cảm ơn dì", 197, 82, 109, 17, _open.bind("hud"), true)
	_button("2  Cháu muốn xem thư", 188, 62, 118, 17, _open.bind("quests"))

func _shop() -> void:
	_farm()
	_fill(Color(INK, 0.52), 0, 0, 320, 180)
	_panel("WoodPanel", 8, 10, 304, 156)
	_panel("PaperPanel", 11, 29, 147, 109)
	_panel("PaperPanel", 162, 29, 147, 109)
	_label("Hàng của tiệm", 17, 12, 136, 16, GOLD, 10)
	_label("Túi đồ", 170, 12, 135, 16, GOLD, 10)
	for i in 4:
		_slot(16, 34 + i * 24, i + 2, i == 0)
		_label(["Hạt cải", "Cải xanh", "Đá", "Gỗ"][i], 41, 37 + i * 24, 79, 16, INK)
		_digits(["15", "20", "8", "10"][i], 121, 37 + i * 24, 28, 16, INK)
	for row in 4:
		for col in 6:
			_slot(171 + col * 20, 36 + row * 23, col if row == 0 else -1)
	_icon("coin", 17, 147)
	_digits("240", 31, 143, 33, 15)
	_label("Tổng", 103, 143, 35, 15)
	_digits("15", 135, 143, 26, 15, CREAM)
	_button("Xác nhận", 231, 142, 75, 18, _open.bind("hud"), true)

func _learning() -> void:
	_farm()
	_fill(Color(INK, 0.48), 0, 0, 320, 180)
	_panel("WoodPanel", 22, 16, 276, 148)
	_panel("PaperPanel", 27, 38, 266, 101)
	_icon("calculator", 30, 21, 12)
	_label("SỔ TAY TRI THỨC", 47, 19, 125, 16, GOLD, 10)
	_label(QUESTIONS[question_index], 183, 21, 108, 12, CREAM, 8, HORIZONTAL_ALIGNMENT_RIGHT)
	var prompts := ["Có 3 luống, mỗi luống có 4 cây.", "Điền từ còn thiếu vào câu.",
		"Xếp các bước trồng cây theo thứ tự.", "Nối vật dụng với công việc.",
		"Có 12 hạt, chia đều cho 3 luống.", "Phân loại vật phẩm trong túi.",
		"Đếm số ô màu Lá trong khu vườn."]
	_label(prompts[question_index], 36, 44, 242, 13, INK)
	match question_index:
		0:
			_label("Có bao nhiêu cây tất cả?", 36, 58, 242, 13, INK)
			for i in 4:
				_answer(["A · 7", "B · 12", "C · 9", "D · 15"][i],
					40 + (i % 2) * 122, 78 + (i / 2) * 23, 111, i)
		1:
			_label("Cháu ___ hạt vào luống đất.", 42, 65, 220, 14, INK, 10)
			_answer("gieo", 44, 94, 73, 0)
			_answer("hái", 123, 94, 73, 1)
			_answer("gặt", 202, 94, 73, 2)
		2:
			_answer("1 · Cuốc đất", 42, 67, 112, 0)
			_answer("2 · Gieo hạt", 163, 67, 112, 1)
			_answer("3 · Tưới nước", 42, 94, 112, 2)
		3:
			for i in 3:
				_answer(["Cuốc", "Bình tưới", "Giỏ"][i], 46, 64 + 22 * i, 74, i)
				_answer(["Chứa đồ", "Làm đất", "Tưới cây"][i], 194, 64 + 22 * i, 80, i + 3)
		4:
			_label("Mỗi luống có bao nhiêu hạt?", 36, 57, 132, 24, INK)
			_panel("WoodPanel", 48, 93, 101, 25)
			_digits(str(selected_answer + 1) if selected_answer >= 0 else "0", 61, 97, 72, 16)
			for i in 9:
				_answer(str(i + 1), 172 + (i % 3) * 34, 63 + (i / 3) * 23, 29, i)
		5:
			for i in 4:
				_slot(64 + 48 * i, 67, i + 1, i == selected_answer)
			_answer("Ăn được", 48, 100, 105, 0)
			_answer("Vật liệu", 163, 100, 105, 1)
		6:
			for y in 4:
				for x in 8:
					var lit := (x + y * 3) % 7 < 3
					_fill(WOOD, 110 + x * 12, 65 + y * 12, 11, 11)
					_fill(GREEN if lit else PAPER, 111 + x * 12, 66 + y * 12, 9, 9)
			_label("Dùng lưới để đếm từng hàng.", 36, 119, 233, 12, INK)
	_button("Dạng trước", 28, 143, 65, 16, _change_question.bind(-1))
	_button("Dạng sau", 97, 143, 65, 16, _change_question.bind(1))
	_button("Bỏ qua tạm", 166, 143, 61, 16, _open.bind("title"))
	_button("Xác nhận", 231, 143, 61, 16, _open.bind("summary"), false, selected_answer < 0)

func _answer(value: String, x: int, y: int, w: int, id: int) -> void:
	_button(value, x, y, w, 20, _select_answer.bind(id), selected_answer == id)

func _select_answer(id: int) -> void:
	selected_answer = id
	_show_page()

func _change_question(direction: int) -> void:
	question_index = posmod(question_index + direction, QUESTIONS.size())
	selected_answer = -1
	_show_page()

func _fishing() -> void:
	_farm()
	_panel("WoodPanel", 8, 8, 124, 26)
	_icon("fish", 14, 16, 12)
	_label("Câu cá · Hồ Gương", 31, 11, 97, 18, GOLD)
	_panel("WoodPanel", 184, 36, 16, 96)
	_fill(BLUE, 187, 40, 10, 88)
	_fill(GREEN, 187, 80, 10, 26)
	_icon("fish", 188, 73)
	_fill(INK, 203, 36, 4, 96)
	_fill(GREEN, 204, 68, 2, 62)
	_bar(136, 51, 48, 6, 0.72, BLUE, WOOD)
	_fill(GOLD, 169, 52, 4, 4)
	_panel("WoodPanel", 96, 143, 128, 22)
	_label("Giữ J để kéo", 101, 147, 118, 13, CREAM, 8, HORIZONTAL_ALIGNMENT_CENTER)

func _combat() -> void:
	_farm()
	_label("BÓNG QUÊN  ·  PHA 2", 60, 1, 200, 13, CREAM, 8, HORIZONTAL_ALIGNMENT_CENTER)
	_bar(60, 16, 200, 8, 0.63, RED, DARK_RED)
	_fill(INK, 126, 17, 1, 6)
	_fill(INK, 192, 17, 1, 6)
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([Vector2(172, 97), Vector2(203, 82), Vector2(253, 99),
		Vector2(222, 123), Vector2(181, 114)])
	marker.color = Color(RED, 0.35)
	world.add_child(marker)
	_icon("spark", 208, 89, 14)
	_label("!", 213, 70, 15, 13, RED, 12)
	_panel("WoodPanel", 80, 121, 160, 40)
	_label("Ký hiệu nào là Tri thức Ngữ?", 86, 124, 148, 13)
	for i in 3:
		_icon(TOPIC_ICONS[i], 108 + i * 42, 140, 12)

func _summary() -> void:
	_pic(ART + "title.png", 0, 0, 320, 180)
	_fill(Color(INK, 0.35), 0, 0, 320, 180)
	_panel("WoodPanel", 45, 13, 230, 154)
	_panel("PaperPanel", 48, 16, 224, 148)
	_label("TỔNG KẾT NGÀY", 54, 20, 212, 17, INK, 12, HORIZONTAL_ALIGNMENT_CENTER)
	for i in 3:
		_icon("spark", 140 + i * 14, 42, 12)
	_fill(WOOD, 57, 58, 206, 1)
	_label("Hôm nay", 58, 62, 65, 14, INK, 10)
	_label("Lên cấp", 136, 62, 65, 14, INK, 10)
	_label("Ngày mai", 205, 62, 62, 14, INK, 10)
	_label("+80 Xu", 58, 81, 65, 14, INK)
	_label("1 nhiệm vụ", 58, 95, 65, 14, INK)
	_label("↑ Canh tác", 136, 81, 65, 14, DARK_GREEN)
	_label("+12 XP", 136, 95, 65, 14, INK)
	_icon("cloud", 211, 84, 12)
	_label("22°C", 230, 84, 35, 14, INK)
	_button("Tiếp tục", 120, 132, 80, 20, _open.bind("hud"), true)

func _saves() -> void:
	_pic(ART + "title.png", 0, 0, 320, 180)
	_fill(Color(INK, 0.48), 0, 0, 320, 180)
	_label("TẢI GAME", 19, 14, 262, 16, GOLD, 12)
	for i in 3:
		var y := 35 + 43 * i
		_panel("WoodPanel", 20, y, 280, 40)
		if i == 0:
			_pic(ART + "farm-preview.png", 24, y + 4, 56, 32)
			_label("Mai · Nông trại Mầm Xanh", 88, y + 3, 178, 14, CREAM, 10)
			_label("Xuân 3 · Năm 1   ·   02:14", 88, y + 22, 160, 12, GOLD)
			_button("Tải", 252, y + 12, 41, 16, _open.bind("hud"), true)
		else:
			_icon("book", 41, y + 11, 16)
			_label("Ô trống", 88, y + 9, 103, 20)
			_button("Trò chơi mới", 210, y + 12, 83, 16, _open.bind("create"))

func _create_character() -> void:
	_farm()
	_fill(Color(INK, 0.58), 0, 0, 320, 180)
	_panel("WoodPanel", 6, 11, 308, 159)
	_panel("PaperPanel", 10, 31, 300, 134)
	_label("TẠO NHÂN VẬT", 15, 14, 160, 15, GOLD, 10)
	_panel("SlotPanel", 14, 38, 80, 84)
	_player_sprite(38, 42, 2)
	_label("Xem trước", 14, 102, 80, 14, INK, 8, HORIZONTAL_ALIGNMENT_CENTER)
	_label("Màu da", 105, 37, 105, 13, INK)
	for i in 8:
		var shade: String = ["#F6CB9E", "#E5AB82", "#D99266", "#C27B56", "#A76245",
			"#8C5038", "#6A3E2F", "#4A2B23"][i]
		_fill(INK, 106 + i * 12, 53, 10, 10)
		_fill(Color(shade), 107 + i * 12, 54, 8, 8)
	_label("Tóc", 105, 69, 105, 13, INK)
	for i in 7:
		_fill(WOOD, 106 + i * 14, 85, 12, 12)
		_fill([INK, WOOD, GOLD, DARK_RED, PURPLE, PAPER, BLUE][i], 108 + i * 14, 87, 8, 8)
	_label("Tên", 215, 37, 82, 13, INK)
	_label("Tên nông trại", 215, 70, 91, 13, INK)
	var player_name := LineEdit.new()
	player_name.max_length = 16
	player_name.placeholder_text = "Tên của bạn"
	_place(player_name, 214, 51, 88, 17)
	var farm_name := LineEdit.new()
	farm_name.max_length = 16
	farm_name.placeholder_text = "Mầm Xanh"
	_place(farm_name, 214, 84, 88, 17)
	var start := _button("Bắt đầu", 219, 138, 80, 19, _open.bind("dialogue"), false, true)
	var update := func(_value: String) -> void:
		start.disabled = player_name.text.strip_edges().is_empty() or farm_name.text.strip_edges().is_empty()
	player_name.text_changed.connect(update)
	farm_name.text_changed.connect(update)
	for i in TOPIC_ICONS.size():
		_icon(TOPIC_ICONS[i], 108 + 18 * i, 124, 12)
	_label("Môn yêu thích", 105, 107, 100, 14, INK)

func _widgets() -> void:
	_farm()
	_fill(Color(INK, 0.60), 0, 0, 320, 180)
	_panel("WoodPanel", 10, 15, 300, 153)
	_panel("PaperPanel", 15, 37, 290, 126)
	_label("SỔ MẪU GIAO DIỆN", 20, 18, 210, 16, GOLD, 12)
	for i in 4:
		_panel(["WoodPanel", "PaperPanel", "SlotPanel", "TabPanel"][i], 24 + 70 * i, 44, 61, 26)
		_label(["Gỗ", "Giấy", "Ô lõm", "Thẻ"][i], 24 + 70 * i, 50, 61, 14,
			INK if i == 1 or i == 2 else CREAM, 8, HORIZONTAL_ALIGNMENT_CENTER)
	_button("Bình thường", 23, 76, 62, 16, func() -> void: pass)
	_button("Focus", 93, 76, 62, 16, func() -> void: pass, true)
	var danger := _button("Cảnh báo", 163, 76, 62, 16, _open.bind("saves"))
	danger.theme_type_variation = &"AlertButton"
	_button("Vô hiệu", 233, 76, 62, 16, func() -> void: pass, false, true)
	_label("8 px · Ắ ệ ỗ ự ỹ Đ", 24, 99, 266, 12, INK, 8)
	_label("10 px · Nông trại Mầm Xanh", 24, 112, 266, 14, INK, 10)
	_label("12 px · Sổ Tay Tri Thức", 24, 128, 266, 16, INK, 12)
	_digits("0123456789", 23, 149, 61, 10, INK)
	for i in 12:
		_icon(["sun", "cloud", "heart", "coin", "bolt", "book", "fish", "gear", "map", "hand", "sword", "leaf"][i],
			104 + i * 15, 150)
