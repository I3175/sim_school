extends Button
var container_id: String = "bag"
var slot_index: int = 0
var amount_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(20, 20)
	expand_icon = true
	add_theme_constant_override("icon_max_width", 14)
	add_theme_font_size_override("font_size", 7)
	amount_label = Label.new()
	amount_label.position = Vector2(7, 10)
	amount_label.add_theme_font_size_override("font_size", 6)
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(amount_label)
	EventBus.inventory_changed.connect(refresh)
	pressed.connect(_select)
	refresh()

func refresh() -> void:
	var slot: Dictionary = InventoryManager.container(container_id).slots[slot_index]
	icon = null
	text = ""
	amount_label.text = ""
	tooltip_text = "Ô trống"
	if not slot.is_empty():
		var item: ItemData = ItemDatabase.get_item(str(slot.id))
		icon = item.icon
		amount_label.text = str(int(slot.amount)) if int(slot.amount) > 1 else ""
		tooltip_text = "%s · %d · chất lượng %d" % [tr(item.name_key), int(slot.amount), int(slot.quality)]
	self_modulate = Color("ffe0a0") if container_id == "bag" and slot_index == InventoryManager.selected_slot else Color.WHITE

func _select() -> void:
	if container_id == "bag" and slot_index < 12:
		InventoryManager.selected_slot = slot_index
		EventBus.inventory_changed.emit()

func _get_drag_data(_at_position: Vector2) -> Variant:
	var slot: Dictionary = InventoryManager.container(container_id).slots[slot_index]
	if slot.is_empty():
		return null
	var amount := int(slot.amount)
	if Input.is_key_pressed(KEY_SHIFT):
		amount = ceili(amount / 2.0)
	var preview := TextureRect.new()
	preview.texture = ItemDatabase.get_item(str(slot.id)).icon
	preview.custom_minimum_size = Vector2(16, 16)
	set_drag_preview(preview)
	return {"container": container_id, "index": slot_index, "amount": amount}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has_all(["container", "index", "amount"])

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	InventoryManager.move(str(data.container), int(data.index), container_id, slot_index, int(data.amount))
