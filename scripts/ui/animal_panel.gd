extends CanvasLayer
var panel: PanelContainer
var rows: VBoxContainer
var system: Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	system = get_parent().get_node("AnimalSystem")
	panel = PanelContainer.new()
	panel.position = Vector2(8, 10)
	panel.custom_minimum_size = Vector2(304, 155)
	panel.theme = preload("res://assets/art/ui/inventory_theme.tres")
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 150)
	panel.add_child(scroll)
	rows = VBoxContainer.new()
	scroll.add_child(rows)
	panel.hide()
	EventBus.animal_panel_requested.connect(_open)

func _open() -> void:
	panel.show()
	EventBus.pause_requested.emit("animals", true)
	get_tree().paused = true
	refresh()

func refresh() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var label := Label.new()
	label.text = "Vật nuôi · Cỏ khô %d · Nước %d" % [system.model.hay, system.model.water]
	rows.add_child(label)
	var actions := HBoxContainer.new()
	rows.add_child(actions)
	_button(actions, "Xây chuồng gà", func() -> void: system.build("coop"); refresh())
	_button(actions, "Xây chuồng bò", func() -> void: system.build("barn"); refresh())
	_button(actions, "Đóng", _close)
	var care := HBoxContainer.new()
	rows.add_child(care)
	_button(care, "Gà 400 Xu", func() -> void: system.buy("chicken"); refresh())
	_button(care, "Bò 1500 Xu", func() -> void: system.buy("cow"); refresh())
	_button(care, "Đổ 5 cỏ", func() -> void: system.feed(5); refresh())
	_button(care, "Nước", func() -> void: system.model.water = 20; refresh())
	var supplies := HBoxContainer.new()
	rows.add_child(supplies)
	_button(supplies, "Mua cỏ 50 Xu", _buy_hay)
	_button(supplies, "Đóng/mở chuồng", func() -> void: system.model.door_open = not system.model.door_open; refresh())
	for index in range(system.model.animals.size()):
		var animal: Dictionary = system.model.animals[index]
		var row := HBoxContainer.new()
		rows.add_child(row)
		var text := Label.new()
		text.text = "%s · %d ngày · vui %d · HP %d%s" % [system.model.definitions[animal.kind].display_name, int(animal.age), int(animal.happiness), int(animal.health), " · Ốm" if animal.sick else ""]
		row.add_child(text)
		_button(row, "Vuốt", func() -> void: system.model.pet(index, GameClock.model.day_index()); refresh())
		_button(row, "Thu", func() -> void: system.collect(index); refresh())

func _buy_hay() -> void:
	var response := {}
	EventBus.inventory_transaction_requested.emit({"coins": -int(system.model.rules.hay_price), "add": [{"id": "hay", "amount": 1}]}, response)
	refresh()

func _button(row: Node, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(action)
	row.add_child(button)

func _close() -> void:
	panel.hide()
	EventBus.pause_requested.emit("animals", false)
	get_tree().paused = not GameClock.model.pauses.is_empty()

func _unhandled_key_input(event: InputEvent) -> void:
	if panel.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()
