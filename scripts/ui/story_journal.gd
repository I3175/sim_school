extends CanvasLayer
var panel: PanelContainer
var text: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = PanelContainer.new()
	panel.position = Vector2(8, 5)
	panel.custom_minimum_size = Vector2(304, 170)
	panel.theme = preload("res://assets/art/ui/inventory_theme.tres")
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(296, 140)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	text = Label.new()
	text.custom_minimum_size.x = 280
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(text)
	var close := Button.new()
	close.text = "Đóng · C / Esc"
	close.pressed.connect(func() -> void: set_open(false))
	column.add_child(close)
	panel.hide()
	EventBus.story_changed.connect(refresh)

func set_open(value: bool) -> void:
	if value and not GameClock.model.pauses.is_empty():
		return
	panel.visible = value
	EventBus.pause_requested.emit("story", value)
	get_tree().paused = not GameClock.model.pauses.is_empty()
	if value: refresh()

func refresh() -> void:
	var story: StoryModel = StoryManager.model
	var day := GameClock.model.day_index()
	var current := story.chapter(day)
	text.text = "SỔ TAY · NGÔI SAO TRI THỨC\n"
	if story.completed < 0:
		text.text += "Lá thư để lại Nông Trại Mầm Xanh và một cuốn sổ trống. Hãy bắt đầu bằng một hạt giống.\n\n"
	if current >= 0:
		text.text += "Chương %d · %s\n" % [current, StoryModel.TITLES[current]]
		for condition: Dictionary in story.requirements(current):
			var caption := str(condition.caption)
			for id: String in StoryModel.NPCS:
				if caption == "Gặp " + id:
					caption = "Gặp " + str(JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs/catalog.json"))[id].name)
			text.text += ("✓ " if condition.done else "□ ") + caption + "\n"
	elif story.completed == 7:
		text.text += "Ngôi Sao đã sáng lại. Hậu kết: " + {"farm": "Nông Trại", "school": "Trường Học", "library": "Thư Viện"}[story.ending]
	else:
		text.text += "Chương tiếp theo mở từ ngày %d. Hãy chăm vườn và thăm bạn bè.\n" % (StoryModel.OPEN_DAYS[story.completed + 1] + 1)
	var festival := story.festival(day, GameClock.model.minute_of_day())
	if festival != "": text.text += "\nHôm nay: " + festival + " · Quảng trường đến 23:00"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C or (panel.visible and event.keycode == KEY_ESCAPE):
			set_open(not panel.visible)
			get_viewport().set_input_as_handled()
