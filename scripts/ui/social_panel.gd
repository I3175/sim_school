extends CanvasLayer
var panel: PanelContainer
var column: VBoxContainer
var text_label: Label
var choices: HBoxContainer
var resource: Resource
var current_line: Variant
var npc_id: String = ""
var busy: bool = false
var typing: float = 0.0
var shop_visible: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = PanelContainer.new()
	panel.position = Vector2(8, 100)
	panel.custom_minimum_size = Vector2(304, 72)
	panel.theme = preload("res://assets/art/ui/inventory_theme.tres")
	add_child(panel)
	column = VBoxContainer.new()
	panel.add_child(column)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(296, 32)
	text_label.add_theme_font_size_override("font_size", 8)
	column.add_child(text_label)
	choices = HBoxContainer.new()
	column.add_child(choices)
	panel.hide()
	EventBus.dialogue_requested.connect(_open)

func _process(delta: float) -> void:
	if panel.visible and text_label.visible_characters >= 0:
		typing += delta * 35.0
		text_label.visible_characters = int(typing)

func _open(id: String, cue: String) -> void:
	if busy or panel.visible:
		return
	shop_visible = false
	npc_id = id
	resource = DialogueManager.create_resource_from_text(FileAccess.get_file_as_string("res://data/npcs/%s.dialogue.txt" % id))
	panel.show()
	EventBus.pause_requested.emit("dialogue", true)
	get_tree().paused = true
	await _next(cue)

func _clear_choices() -> void:
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()

func _next(cue: String) -> void:
	if busy:
		return
	busy = true
	current_line = await DialogueManager.get_next_dialogue_line(resource, cue)
	busy = false
	if current_line == null:
		_close()
		return
	text_label.text = "%s: %s" % [current_line.character, current_line.text]
	typing = 0.0
	text_label.visible_characters = 0
	_clear_choices()
	for response in current_line.responses:
		_button(response.text, func() -> void: _next(response.next_id))
	if current_line.responses.is_empty():
		_button("Tiếp", func() -> void: _next(current_line.next_id))
	_button("Tặng", func() -> void: EventBus.npc_gift_requested.emit(npc_id); _close())
	if npc_id == "di_nam":
		_button("Mua bán", _show_shop)

func _button(caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(action)
	choices.add_child(button)

func _show_shop() -> void:
	shop_visible = true
	_clear_choices()
	text_label.visible_characters = -1
	text_label.text = "Tiệm Dì Năm · %d Xu · Chọn hạt để mua 1" % InventoryManager.coins
	var crops: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops/catalog.json"))
	for crop_id: String in crops:
		var crop: CropData = load("res://data/crops/%s.tres" % crop_id)
		if GameClock.model.season_index() not in crop.seasons:
			continue
		var item: ItemData = ItemDatabase.get_item(crop.seed_id)
		_button("%s %d" % [tr(item.name_key).trim_prefix("Hạt "), item.buy_price], func() -> void: _buy(item.id))
	_button("Bán ô chọn", _sell)
	_button("Đóng", _close)

func _shop_open() -> bool:
	return MapRules.available(SceneManager.definitions.grocery, GameClock.model.minute_of_day(), GameClock.model.day_index() % 7, SceneManager.flags)

func _buy(id: String) -> void:
	if not _shop_open():
		text_label.text = "Tiệm đang đóng cửa"
		return
	var item: ItemData = ItemDatabase.get_item(id)
	var response := {}
	EventBus.inventory_transaction_requested.emit({"add": [{"id": id, "amount": 1}], "coins": -item.buy_price}, response)
	_show_shop()
	if not response.get("success", false):
		text_label.text = "Không đủ Xu hoặc túi đầy"

func _sell() -> void:
	if not _shop_open():
		return
	var slot: Dictionary = InventoryManager.bag.slots[InventoryManager.selected_slot]
	if slot.is_empty():
		return
	var item: ItemData = ItemDatabase.get_item(str(slot.id))
	if item.sell_price <= 0:
		return
	var multipliers: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/farming.json")).quality_multipliers
	var response := {}
	EventBus.inventory_transaction_requested.emit({"remove": [{"id": item.id, "amount": 1, "quality": int(slot.quality)}], "coins": floori(item.sell_price * float(multipliers[int(slot.quality)]))}, response)
	_show_shop()

func _close() -> void:
	panel.hide()
	EventBus.pause_requested.emit("dialogue", false)
	get_tree().paused = not GameClock.model.pauses.is_empty()

func _unhandled_key_input(event: InputEvent) -> void:
	if not panel.visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_close()
	elif event.keycode == KEY_E and current_line != null and not shop_visible:
		if text_label.visible_characters < text_label.text.length():
			typing = text_label.text.length()
			text_label.visible_characters = -1
		elif current_line.responses.is_empty():
			_next(current_line.next_id)
	get_viewport().set_input_as_handled()
