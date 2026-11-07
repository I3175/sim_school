extends CanvasLayer

var model: ZeroEncounterModel
var panel: PanelContainer
var canvas: Control
var title: Label
var message: Label
var cooldown: float = 0.0
var status: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	panel = PanelContainer.new()
	panel.position = Vector2(8, 4)
	panel.size = Vector2(304, 172)
	panel.theme = preload("res://assets/art/ui/inventory_theme.tres")
	add_child(panel)
	canvas = Control.new()
	canvas.custom_minimum_size = Vector2(300, 168)
	canvas.draw.connect(_draw_arena)
	panel.add_child(canvas)
	title = Label.new()
	title.position = Vector2(6, 2)
	title.add_theme_font_size_override("font_size", 8)
	canvas.add_child(title)
	message = Label.new()
	message.position = Vector2(6, 16)
	message.size = Vector2(286, 34)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 8)
	canvas.add_child(message)
	var help := Label.new()
	help.position = Vector2(6, 152)
	help.text = "WASD / mũi tên · J đánh đáp án · Esc rút lui"
	help.add_theme_font_size_override("font_size", 7)
	canvas.add_child(help)
	panel.hide()
	EventBus.map_entered.connect(_station)
	EventBus.player_fainted.connect(close)

func _station(map_id: String) -> void:
	if map_id != "school": return
	var map: Node = SceneManager.cache[map_id]
	if map.has_node("ZeroEntrance"): return
	var entrance := Interactable.new()
	entrance.name = "ZeroEntrance"
	entrance.position = Vector2(104, 112)
	entrance.prompt = "Hầm trường"
	entrance.action = open
	map.add_child(entrance)

func open() -> void:
	if panel.visible or not GameClock.model.pauses.is_empty(): return
	if not StoryManager.model.can_challenge("zero", GameClock.model.day_index(), GameClock.model.minute_of_day()):
		EventBus.notice_requested.emit("Hầm trường mở trong chương Ngôi Trường Im Lặng.")
		return
	model = ZeroEncounterModel.new()
	cooldown = 0
	status = ""
	panel.show()
	EventBus.pause_requested.emit("zero_encounter", true)
	get_tree().paused = true

func close() -> void:
	if not panel.visible: return
	panel.hide()
	EventBus.pause_requested.emit("zero_encounter", false)
	get_tree().paused = not GameClock.model.pauses.is_empty()

func _process(delta: float) -> void:
	if not panel.visible: return
	if not is_instance_valid(SceneManager.player):
		close()
		return
	cooldown = maxf(0, cooldown - delta)
	var damage := model.tick(minf(delta, 0.05), Input.get_vector("move_left", "move_right", "move_up", "move_down"))
	# The world is paused during this prototype arena, so advance its hurt timer here.
	SceneManager.player.hurt_cooldown = maxf(0, SceneManager.player.hurt_cooldown - delta)
	if damage > 0: SceneManager.player.take_damage(damage)
	title.text = "BÓNG SỐ KHÔNG · %d/3 vết nứt · HP %d" % [model.round_index, SceneManager.player.health]
	if model.phase == "dodge":
		message.text = "Né ô vàng trước khi số rơi! %.1f giây" % maxf(0, float(model.rules.dodge_seconds) - model.elapsed)
	elif model.phase == "answer":
		message.text = str(model.rules.rounds[model.round_index].prompt) + " Đến gần đáp án và đánh.\n" + (model.hint() if model.mistakes >= 3 else status)
	elif model.phase == "won":
		message.text = "Mảnh Số đã sáng lại! Cô Lan và lớp học được nhắc nhớ.\nNhấn Esc để trở về trường."
	canvas.queue_redraw()

func _draw_arena() -> void:
	if model == null: return
	canvas.draw_rect(ZeroEncounterModel.ARENA, Color("344650"))
	var font := ThemeDB.fallback_font
	for hazard: Dictionary in model.hazards:
		var active: bool = float(hazard.age) >= float(model.rules.warning_seconds)
		canvas.draw_rect(Rect2(hazard.center - Vector2(13, 13), Vector2(26, 26)), Color("ee6856") if active else Color("c5a649"), active, -1 if active else 2)
		canvas.draw_string(font, hazard.center + Vector2(-3, 3), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	if model.phase == "answer":
		for index in range(ZeroEncounterModel.TARGETS.size()):
			var point := ZeroEncounterModel.TARGETS[index]
			canvas.draw_circle(point, 11, Color("8b689a"))
			canvas.draw_string(font, point + Vector2(-5, 3), str(int(model.rules.rounds[model.round_index].answers[index])), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	canvas.draw_circle(model.position + Vector2(0, 3), 5, Color("20322f"))
	canvas.draw_rect(Rect2(model.position - Vector2(4, 6), Vector2(8, 10)), Color("8abccd"))
	canvas.draw_rect(Rect2(model.position - Vector2(3, 9), Vector2(6, 5)), Color("e9bd91"))

func _unhandled_key_input(event: InputEvent) -> void:
	if not panel.visible or not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE:
		close()
	elif event.keycode == KEY_J and cooldown <= 0:
		cooldown = 0.3
		var result := model.attack()
		match result.result:
			"wrong":
				SceneManager.player.take_damage(int(result.damage))
				status = "Chưa đúng. Thử tính lại nhé."
			"out_of_range": status = "Tiến gần con số trước khi đánh."
			"cracked": status = "Đúng! Một vết nứt đã xuất hiện."
			"won":
				if not StoryManager.complete_boss("zero"):
					status = "Tiến độ đã thay đổi; không trao mảnh lần hai."
	get_viewport().set_input_as_handled()
