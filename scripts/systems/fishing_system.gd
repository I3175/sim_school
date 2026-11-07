extends CanvasLayer
const WATER = preload("res://scripts/entities/fishing_water.gd")
var model := FishingModel.new()
var waters: Array[Node2D] = []
var panel: PanelContainer
var label: Label
var bars: Array[ProgressBar] = []
var attempts: int = 0
var pending: Dictionary = {}
var fishing_xp: int = 0
var traps: Dictionary = {}

func _ready() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(72, 60)
	panel.custom_minimum_size = Vector2(176, 72)
	panel.theme = preload("res://assets/art/ui/inventory_theme.tres")
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 168
	column.add_child(label)
	for index in range(3):
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(168, 6)
		bar.show_percentage = false
		bar.max_value = 1.0
		column.add_child(bar)
		bars.append(bar)
	panel.hide()
	EventBus.map_entered.connect(_map_entered)
	EventBus.day_started.connect(_new_day)
	EventBus.state_save_requested.connect(_save)
	EventBus.state_load_requested.connect(_load)

func _map_entered(id: String) -> void:
	waters.clear()
	if id not in ["mirror_lake", "golden_beach", "farm_main"]:
		return
	var map: Node = SceneManager.cache[id]
	var zone_ids: Array = ["lake", "river", "waterfall"] if id == "mirror_lake" else (["sea"] if id == "golden_beach" else ["river"])
	for index in range(zone_ids.size()):
		var node_name := "Water_" + str(zone_ids[index])
		var water: Node2D = map.get_node_or_null(NodePath(node_name))
		if water == null:
			water = Node2D.new()
			water.set_script(WATER)
			water.name = node_name
			water.zone_id = str(zone_ids[index])
			var spawn: Array = SceneManager.definitions[id].spawn
			water.position = Vector2(float(spawn[0]) + 160.0 * (index + 1), float(spawn[1]) - 80.0)
			map.add_child(water)
		waters.append(water)

func _shore() -> Node2D:
	if not is_instance_valid(SceneManager.player):
		return null
	for water in waters:
		if is_instance_valid(water) and water.near_shore(SceneManager.player.global_position):
			return water
	return null

func _process(delta: float) -> void:
	model.tick(delta, Input.is_physical_key_pressed(KEY_J))
	if model.state == "idle":
		return
	panel.show()
	var texts := {"casting": "Giữ J nạp lực, thả để quăng", "waiting": "Đợi cá cắn câu…", "bite": "! Nhấn J ngay", "reeling": "Giữ J nâng thanh; thả để hạ\nThanh 1: cá · 2: bạn · 3: tiến độ", "caught": "Đã câu được cá!", "escaped": "Cá đã thoát"}
	label.text = str(texts.get(model.state, ""))
	bars[0].value = model.cast_power if model.state == "casting" else model.fish_position
	bars[1].value = model.bar
	bars[2].value = model.progress
	if model.state == "caught" and pending.is_empty():
		pending = model.reward()
		_try_collect()
	elif model.state == "caught" and not pending.is_empty():
		label.text = "Túi đầy. Mở I để sắp đồ, E nhận cá."
	elif model.state == "escaped":
		EventBus.notice_requested.emit("Cá đã thoát")
		_finish()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_ESCAPE and event.pressed and model.state != "idle" and pending.is_empty():
			_finish()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E and event.pressed:
			if not pending.is_empty():
				_try_collect()
			elif model.state == "idle":
				_trap_action()
		elif event.physical_keycode == KEY_J or event.keycode == KEY_J:
			if event.pressed:
				if model.state == "bite":
					model.hook()
				elif model.state == "idle":
					_begin()
			else:
				model.release_cast()
			if model.state != "idle":
				get_viewport().set_input_as_handled()

func _begin() -> void:
	var water := _shore()
	var slot: Dictionary = InventoryManager.bag.slots[InventoryManager.selected_slot]
	if water == null or slot.get("id", "") != "bamboo_rod" or SceneManager.player.stamina < float(model.rules.cast_cost):
		return
	var zone: String = water.zone_id
	if zone == "lake" and GameClock.model.season_index() == 3:
		zone = "ice_lake"
	var available := model.eligible(zone, GameClock.model.season_index(), GameClock.model.minute_of_day(), WeatherSystem.current_weather, WeatherSystem.state.get("special_flags", []))
	attempts += 1
	if model.begin(available, hash("%d:%d:%d" % [GameClock.world_seed, GameClock.model.day_index(), attempts])):
		SceneManager.player.stamina -= float(model.rules.cast_cost)
		SceneManager.player.input_enabled = false
	else:
		EventBus.notice_requested.emit("Không có cá phù hợp mùa, giờ và thời tiết")

func _try_collect() -> void:
	var response := {}
	EventBus.inventory_transaction_requested.emit({"add": [pending]}, response)
	if response.get("success", false):
		fishing_xp += int(pending.xp)
		EventBus.resident_xp_awarded.emit(roundi(int(pending.xp) * 0.5))
		EventBus.fish_caught.emit(str(model.fish.id))
		EventBus.notice_requested.emit("Câu được " + str(model.fish.name))
		pending.clear()
		_finish()

func _finish() -> void:
	model.state = "idle"
	panel.hide()
	if is_instance_valid(SceneManager.player):
		SceneManager.player.input_enabled = true

func _trap_action() -> void:
	var water := _shore()
	if water == null:
		return
	var key := SceneManager.current_map_id + ":" + str(water.zone_id)
	var response := {}
	if traps.has(key):
		var trap: Dictionary = traps[key]
		if not trap.product.is_empty():
			EventBus.inventory_transaction_requested.emit({"add": [trap.product]}, response)
			if response.get("success", false):
				trap.product = {}
		elif not trap.baited:
			EventBus.inventory_transaction_requested.emit({"remove": [{"id": "bait", "amount": 1}]}, response)
			trap.baited = response.get("success", false)
	else:
		var slot: Dictionary = InventoryManager.bag.slots[InventoryManager.selected_slot]
		if slot.get("id", "") != "crab_trap":
			return
		EventBus.inventory_transaction_requested.emit({"remove": [{"id": "crab_trap", "amount": 1}, {"id": "bait", "amount": 1}]}, response)
		if response.get("success", false):
			traps[key] = {"baited": true, "product": {}}

func _new_day(day: int) -> void:
	for key: String in traps:
		if traps[key].baited and traps[key].product.is_empty():
			var index: int = posmod(hash("%d:%s:%d" % [GameClock.world_seed, key, day]), model.rules.trap_items.size())
			traps[key].product = {"id": model.rules.trap_items[index], "amount": 1, "quality": 0}
			traps[key].baited = false

func _save(state: Dictionary) -> void:
	state.fishing = {"attempts": attempts, "xp": fishing_xp, "traps": traps.duplicate(true), "pending": pending.duplicate(true)}

func _load(state: Dictionary) -> void:
	var saved: Dictionary = state.get("fishing", {})
	attempts = int(saved.get("attempts", 0))
	fishing_xp = int(saved.get("xp", 0))
	traps = saved.get("traps", {}).duplicate(true)
	pending = saved.get("pending", {}).duplicate(true)
	_finish()
	if not pending.is_empty():
		# Preserve caught fish without rerolling or discarding it on load.
		model.fish = {"id": str(pending.id).trim_prefix("fish_"), "name": tr(ItemDatabase.get_item(str(pending.id)).name_key)}
		model.state = "caught"
