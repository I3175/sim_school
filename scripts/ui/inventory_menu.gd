extends CanvasLayer
const SLOT = preload("res://scripts/ui/inventory_slot.gd")
var panel: PanelContainer
var message: Label
var hotbar: HBoxContainer
var chest_id: String = "farm_chest_01"
var menu_open: bool = false
var grids: Array[GridContainer] = []
var header: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TranslationServer.set_locale("vi")
	hotbar = HBoxContainer.new()
	hotbar.position = Vector2(28, 156)
	hotbar.theme = preload("res://assets/art/ui/inventory_theme.tres")
	hotbar.add_theme_constant_override("separation", 0)
	add_child(hotbar)
	for index in range(12):
		_add_slot(hotbar, "bag", index)
	panel = PanelContainer.new()
	panel.position = Vector2(24, 3)
	panel.theme = preload("res://assets/art/ui/inventory_theme.tres")
	panel.size = Vector2(264, 130)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	panel.add_child(column)
	header = Label.new()
	header.text = "Túi đồ · Shift+kéo: tách · I: đóng"
	header.add_theme_font_size_override("font_size", 8)
	column.add_child(header)
	var inventories := HBoxContainer.new()
	inventories.add_theme_constant_override("separation", 12)
	column.add_child(inventories)
	for id: String in ["bag", chest_id]:
		var grid := GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 0)
		grid.add_theme_constant_override("v_separation", 0)
		inventories.add_child(grid)
		grids.append(grid)
		for index in range(36):
			_add_slot(grid, id, index)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	_add_button(actions, "Xếp", func() -> void: InventoryManager.bag.sort_items(); EventBus.inventory_changed.emit())
	for slot in range(3):
		_add_button(actions, "L%d" % (slot + 1), func() -> void: EventBus.save_requested.emit(slot))
		_add_button(actions, "T%d" % (slot + 1), func() -> void: EventBus.load_requested.emit(slot))
	message = Label.new()
	message.position = Vector2(8, 145)
	message.add_theme_font_size_override("font_size", 8)
	add_child(message)
	EventBus.save_finished.connect(func(_success: bool, text: String) -> void: message.text = text)
	EventBus.notice_requested.connect(func(text: String) -> void: message.text = text)
	panel.hide()

func _add_button(parent: Node, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(action)
	parent.add_child(button)

func _add_slot(parent: Node, id: String, index: int) -> void:
	var slot := Button.new()
	slot.set_script(SLOT)
	slot.container_id = id
	slot.slot_index = index
	parent.add_child(slot)

func _unhandled_input(event: InputEvent) -> void:
	if not menu_open and not GameClock.model.pauses.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_I, KEY_TAB] or (event.keycode == KEY_ESCAPE and menu_open):
			set_open(not menu_open)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E and not menu_open:
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if player != null and SceneManager.current_map_id == "farm_main" and player.position.distance_to(Vector2(680, 480)) <= 28.0:
				set_open(true, true)
				get_viewport().set_input_as_handled()
		elif not menu_open:
			var keys: Array = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL]
			if event.keycode in keys:
				InventoryManager.selected_slot = keys.find(event.keycode)
				EventBus.inventory_changed.emit()
	elif event is InputEventMouseButton and event.pressed and not menu_open:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var direction := -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
			InventoryManager.selected_slot = posmod(InventoryManager.selected_slot + direction, 12)
			EventBus.inventory_changed.emit()

func set_open(open: bool, with_chest: bool = false) -> void:
	grids[0].columns = 6 if with_chest else 12
	grids[1].visible = with_chest
	header.text = "Túi / Rương · Shift+kéo: tách · I: đóng" if with_chest else "Túi đồ · Shift+kéo: tách · I: đóng"
	panel.size = Vector2(264, 0)
	menu_open = open
	panel.visible = open
	hotbar.visible = not open
	EventBus.pause_requested.emit("inventory", open)
	get_tree().paused = not GameClock.model.pauses.is_empty()
