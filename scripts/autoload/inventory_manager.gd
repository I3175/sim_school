extends Node
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/inventory.json"))
var bag: InventoryModel
var chests: Dictionary = {}
var selected_slot: int = 0
var coins: int = 0
func _ready() -> void:
	EventBus.inventory_transaction_requested.connect(_transaction)
	# ItemDatabase is registered first in project.godot.
	bag = InventoryModel.new(ItemDatabase.items, int(rules.bag_slots))
	coins = int(rules.starting_coins)
	for item: Dictionary in rules.starting_items:
		bag.add(str(item.id), int(item.amount))
	EventBus.state_save_requested.connect(_collect_state)
	EventBus.state_validate_requested.connect(_validate_state)
	EventBus.state_load_requested.connect(_load_state)

func chest(id: String) -> InventoryModel:
	if not chests.has(id):
		chests[id] = InventoryModel.new(ItemDatabase.items, int(rules.chest_slots))
	return chests[id]

func container(id: String) -> InventoryModel:
	return bag if id == "bag" else chest(id)

func move(source: String, source_index: int, target: String, target_index: int, amount: int = -1) -> bool:
	var success := container(source).move_to(source_index, container(target), target_index, amount)
	if success:
		EventBus.inventory_changed.emit()
	return success

func add(id: String, amount: int, quality: int = 0) -> int:
	var remaining := bag.add(id, amount, quality)
	if remaining < amount:
		EventBus.item_added.emit(id, amount - remaining)
		EventBus.inventory_changed.emit()
	return remaining

func _collect_state(state: Dictionary) -> void:
	var chest_data := {}
	for id: String in chests:
		chest_data[id] = chests[id].slots.duplicate(true)
	state.inventory = {"bag": bag.slots.duplicate(true), "chests": chest_data, "selected_slot": selected_slot, "coins": coins}

func _validate_state(state: Dictionary, errors: Array) -> void:
	var saved: Variant = state.get("inventory")
	if not saved is Dictionary or not bag.valid_snapshot(saved.get("bag")):
		errors.append("Túi đồ không hợp lệ")
		return
	if not saved.get("chests") is Dictionary or not saved.get("selected_slot") is float and not saved.get("selected_slot") is int:
		errors.append("Dữ liệu rương/hotbar không hợp lệ")
		return
	if int(saved.selected_slot) < 0 or int(saved.selected_slot) >= int(rules.hotbar_slots) or not (saved.get("coins") is int or saved.get("coins") is float) or float(saved.coins) < 0:
		errors.append("Hotbar/Xu không hợp lệ")
	for id: String in saved.chests:
		var candidate := InventoryModel.new(ItemDatabase.items, int(rules.chest_slots))
		if not candidate.valid_snapshot(saved.chests[id]):
			errors.append("Rương không hợp lệ: " + id)

func _load_state(state: Dictionary) -> void:
	var saved: Dictionary = state.inventory
	bag.restore(saved.bag)
	chests.clear()
	for id: String in saved.chests:
		chest(id).restore(saved.chests[id])
	selected_slot = int(saved.selected_slot)
	coins = int(saved.coins)
	EventBus.inventory_changed.emit()

func _transaction(request: Dictionary, response: Dictionary) -> void:
	response.success = false
	var trial := InventoryModel.new(ItemDatabase.items, bag.slots.size())
	trial.restore(bag.slots)
	for item: Dictionary in request.get("remove", []):
		if not trial.remove(str(item.id), int(item.amount), int(item.get("quality", -1))):
			return
	for item: Dictionary in request.get("add", []):
		if trial.add(str(item.id), int(item.amount), int(item.get("quality", 0))) != 0:
			return
	var next_coins: int = coins + int(request.get("coins", 0))
	if next_coins < 0:
		return
	bag.restore(trial.slots)
	coins = next_coins
	response.success = true
	EventBus.inventory_changed.emit()
