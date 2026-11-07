extends Node2D
var model := FarmingModel.new()
var target_cell: Vector2i
var last_target := Vector2i(-1, -1)

func _ready() -> void:
	model.last_day = GameClock.model.day_index()
	model.world_seed = GameClock.world_seed
	EventBus.day_started.connect(_on_day_started)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.state_save_requested.connect(_save)
	EventBus.state_validate_requested.connect(_validate)
	EventBus.state_load_requested.connect(_load)

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as VillagePlayer
	if player == null:
		return
	var direction := Vector2.DOWN
	if player.direction_index == 1:
		direction = Vector2.UP
	elif player.direction_index == 2:
		direction = Vector2.RIGHT if player.facing_right else Vector2.LEFT
	target_cell = Vector2i((player.position + direction * 16.0) / 16.0)
	if target_cell != last_target:
		last_target = target_cell
		queue_redraw()

func _key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _in_field(cell: Vector2i) -> bool:
	var origin: Array = model.rules.field_origin
	var dimensions: Array = model.rules.field_size
	return Rect2i(int(origin[0]), int(origin[1]), int(dimensions[0]), int(dimensions[1])).has_point(cell)

func _unhandled_input(event: InputEvent) -> void:
	var use: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J
	use = use or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var interact: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E
	if not use and not interact:
		return
	var player := get_tree().get_first_node_in_group("player") as VillagePlayer
	if player == null:
		return
	if interact and player.position.distance_to(Vector2(712, 480)) < 28.0:
		_ship_selected()
		return
	if not _in_field(target_cell):
		return
	var key := _key(target_cell)
	if interact:
		_harvest(key)
	elif use:
		_use_tool(key, player)
	queue_redraw()

func _use_tool(key: String, player: VillagePlayer) -> void:
	var slot: Dictionary = InventoryManager.bag.slots[InventoryManager.selected_slot]
	if slot.is_empty():
		return
	var id: String = str(slot.id)
	var cost: float = float(model.rules.hoe_cost if id == "hoe" else model.rules.water_cost)
	if id.begins_with("seed_"):
		cost = float(model.rules.seed_cost)
	if player.stamina < cost:
		EventBus.notice_requested.emit("Không đủ thể lực")
		return
	var success := false
	if id == "hoe":
		success = model.till(key)
	elif id == "watering_can":
		success = model.water(key)
	elif id.begins_with("seed_"):
		var crop_id := id.trim_prefix("seed_")
		success = model.plant(key, crop_id, GameClock.model.season_index())
		if success:
			var response := {}
			EventBus.inventory_transaction_requested.emit({"remove": [{"id": id, "amount": 1}]}, response)
			if not response.get("success", false):
				model.cells[key].crop = ""
				success = false
			elif (model.crops[crop_id] as CropData).growth_days > 7 - GameClock.model.day_of_season():
				EventBus.notice_requested.emit("Cảnh báo: cây có thể chưa chín trước khi đổi mùa")
		else:
			EventBus.notice_requested.emit("Cần đất đã cuốc, đúng mùa và nơi trồng")
	if success:
		player.stamina -= cost
		_on_weather_changed(WeatherSystem.current_weather)

func _harvest(key: String) -> void:
	if not model.mature(key):
		return
	var crop: CropData = model.crops[model.cells[key].crop]
	var quality := model.harvest_quality(key)
	var response := {}
	EventBus.inventory_transaction_requested.emit({"add": [{"id": crop.harvest_id, "amount": 1, "quality": quality}]}, response)
	if response.get("success", false):
		model.harvest(key, quality)
		EventBus.crop_harvested.emit(crop.id, quality)
		EventBus.notice_requested.emit("Đã thu hoạch " + tr(ItemDatabase.get_item(crop.harvest_id).name_key))
	else:
		EventBus.notice_requested.emit("Túi đầy — cây vẫn ở đây")

func _ship_selected() -> void:
	var slot: Dictionary = InventoryManager.bag.slots[InventoryManager.selected_slot]
	if slot.is_empty():
		return
	var item: ItemData = ItemDatabase.get_item(str(slot.id))
	if item.sell_price <= 0:
		EventBus.notice_requested.emit("Vật phẩm này không bán được")
		return
	var shipped := slot.duplicate(true)
	var response := {}
	EventBus.inventory_transaction_requested.emit({"remove": [{"id": item.id, "amount": int(slot.amount), "quality": int(slot.quality)}]}, response)
	if response.get("success", false):
		model.shipping.append(shipped)
		EventBus.notice_requested.emit("Đã gửi hàng. Nhận Xu vào sáng mai.")

func _on_day_started(index: int) -> void:
	if index <= model.last_day:
		return
	var income := 0
	for slot: Dictionary in model.shipping:
		var item: ItemData = ItemDatabase.get_item(str(slot.id))
		income += floori(item.sell_price * int(slot.amount) * float(model.rules.quality_multipliers[int(slot.quality)]))
	model.shipping.clear()
	var response := {}
	EventBus.inventory_transaction_requested.emit({"coins": income}, response)
	model.advance_day(index, GameClock.model.season_index(), WeatherSystem.current_weather in ["rain", "drizzle", "storm"])
	if income > 0:
		EventBus.notice_requested.emit("Hàng bán: +%d Xu" % income)
	queue_redraw()

func _on_weather_changed(weather: String) -> void:
	if weather in ["rain", "drizzle", "storm"]:
		model.rain()
		queue_redraw()

func _on_hour_changed(hour: int) -> void:
	if hour == 12 and WeatherSystem.current_weather == "heat":
		for cell: Dictionary in model.cells.values():
			if not cell.sheltered:
				cell.watered = false
		queue_redraw()

func _save(state: Dictionary) -> void:
	state.maps.farm_main = model.snapshot()

func _validate(state: Dictionary, errors: Array) -> void:
	if not state.get("maps") is Dictionary or not model.valid_snapshot(state.maps.get("farm_main")):
		errors.append("Dữ liệu nông trại không hợp lệ")
		return
	for stack: Variant in state.maps.farm_main.shipping:
		var validator := InventoryModel.new(ItemDatabase.items, 1)
		if not validator.valid_snapshot([stack]):
			errors.append("Hòm gửi hàng không hợp lệ")

func _load(state: Dictionary) -> void:
	model.restore(state.maps.farm_main)
	model.world_seed = GameClock.world_seed
	queue_redraw()

func _draw() -> void:
	var origin: Array = model.rules.field_origin
	var dimensions: Array = model.rules.field_size
	draw_rect(Rect2(int(origin[0]) * 16, int(origin[1]) * 16, int(dimensions[0]) * 16, int(dimensions[1]) * 16), Color("c0ae78"), false, 1)
	for key: String in model.cells:
		var parts := key.split(",")
		var location := Vector2(float(parts[0]), float(parts[1])) * 16.0
		var cell: Dictionary = model.cells[key]
		draw_rect(Rect2(location + Vector2.ONE, Vector2(14, 14)), Color("76533b") if cell.watered else Color("b68552"))
		if cell.crop != "":
			var height := mini(10, 2 + int(cell.growth) * 2)
			var tint := Color("b2d36c") if model.mature(key) else Color("569550")
			if cell.withered:
				tint = Color("7b6556")
			draw_rect(Rect2(location + Vector2(5, 13 - height), Vector2(6, height)), tint)
	if _in_field(target_cell):
		draw_rect(Rect2(Vector2(target_cell) * 16.0, Vector2(16, 16)), Color("fff2a9"), false, 1)
	draw_rect(Rect2(705, 467, 14, 13), Color("855539"))
	draw_rect(Rect2(707, 469, 10, 2), Color("e3b971"))
