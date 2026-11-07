extends CanvasLayer
var panel: PanelContainer
var rows: VBoxContainer
var tracking: Label
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = PanelContainer.new()
	panel.position = Vector2(8, 12)
	panel.custom_minimum_size = Vector2(304, 152)
	panel.theme = preload("res://assets/art/ui/inventory_theme.tres")
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 148)
	panel.add_child(scroll)
	rows = VBoxContainer.new()
	scroll.add_child(rows)
	tracking = Label.new()
	tracking.position = Vector2(4, 36)
	tracking.add_theme_font_size_override("font_size", 8)
	add_child(tracking)
	panel.hide()
	EventBus.quests_changed.connect(refresh)
	refresh()

func _process(_delta: float) -> void:
	tracking.visible = GameClock.model.pauses.is_empty()

func refresh() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	tracking.text = ""
	for id: String in QuestManager.model.definitions:
		var quest: QuestData = QuestManager.model.definitions[id]
		var state: Dictionary = QuestManager.model.states[id]
		if state.status == "Locked":
			continue
		var row := HBoxContainer.new()
		rows.add_child(row)
		var label := Label.new()
		label.text = "%s · %s" % [tr(quest.title_key), state.status]
		label.add_theme_font_size_override("font_size", 8)
		row.add_child(label)
		if state.status == "Available":
			_button(row, "Nhận", func() -> void: QuestManager.accept(id))
		elif state.status == "Ready":
			_button(row, "Lĩnh thưởng", func() -> void: QuestManager.claim(id))
		if state.status in ["Active", "Ready"]:
			_button(row, "Ghim", func() -> void: QuestManager.model.pin(id); refresh())
		if id in QuestManager.model.pinned:
			tracking.text += "%s %s\n" % [tr(quest.title_key), str(state.progress)]

func _button(row: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(action)
	row.add_child(button)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_Q or (event.keycode == KEY_ESCAPE and panel.visible):
		if not panel.visible and not GameClock.model.pauses.is_empty():
			return
		panel.visible = not panel.visible
		EventBus.pause_requested.emit("journal", panel.visible)
		get_tree().paused = not GameClock.model.pauses.is_empty()
		get_viewport().set_input_as_handled()
