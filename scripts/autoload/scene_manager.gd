extends Node
const REGION_SCRIPT = preload("res://scripts/entities/region_map.gd")
var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/world.json"))
var cache: Dictionary = {}
var flags: Dictionary = {}
var current_map_id: String = "farm_main"
var host: Node2D
var player: VillagePlayer
var curtain: ColorRect
var transitioning: bool = false

func _ready() -> void:
	EventBus.forced_sleep_triggered.connect(_forced_sleep)
	EventBus.player_fainted.connect(_player_fainted)
	EventBus.map_change_requested.connect(request_transition)
	EventBus.flag_unlocked.connect(func(flag: String) -> void: flags[flag] = true)
	EventBus.state_save_requested.connect(_save_state)
	EventBus.state_validate_requested.connect(_validate_state)
	EventBus.state_restored.connect(_after_restore)
	EventBus.state_load_requested.connect(_load_state)

func configure(map_host: Node2D, main_player: VillagePlayer, fade: ColorRect) -> void:
	host = map_host
	player = main_player
	curtain = fade
	cache.clear()
	_activate("farm_main", Vector2(640, 480))

func request_transition(map_id: String, spawn: Vector2) -> void:
	if transitioning or not is_instance_valid(host) or not definitions.has(map_id):
		return
	if not MapRules.available(definitions[map_id], GameClock.model.minute_of_day(), GameClock.model.day_index() % 7, flags):
		EventBus.notice_requested.emit("Cửa đang đóng hoặc khu vực chưa mở khóa")
		return
	transitioning = true
	player.input_enabled = false
	var fade_out := create_tween()
	fade_out.tween_property(curtain, "color:a", 1.0, 0.25)
	await fade_out.finished
	_activate(map_id, spawn)
	var fade_in := create_tween()
	fade_in.tween_property(curtain, "color:a", 0.0, 0.25)
	await fade_in.finished
	player.input_enabled = true
	transitioning = false

func _build(map_id: String) -> Node2D:
	var map: Node2D
	if map_id == "farm_main":
		map = load("res://scenes/maps/farm_main.tscn").instantiate()
		map.spawn_player = false
		for child_name: String in ["HUD", "InventoryUI", "Lighting"]:
			var child := map.get_node(child_name)
			map.remove_child(child)
			child.free()
	else:
		map = Node2D.new()
		map.set_script(REGION_SCRIPT)
		map.definition = definitions[map_id]
	map.name = map_id
	host.add_child(map)
	_add_portals(map, map_id)
	_add_navigation(map, definitions[map_id])
	cache[map_id] = map
	return map

func _activate(map_id: String, spawn: Vector2) -> void:
	if player.get_parent() != host:
		player.reparent(host)
	for existing: Node2D in cache.values():
		if existing.get_parent() == host:
			host.remove_child(existing)
	var map: Node2D = cache.get(map_id)
	if map == null:
		map = _build(map_id)
	if map.get_parent() == null:
		host.add_child(map)
	map.show()
	map.process_mode = Node.PROCESS_MODE_INHERIT
	player.reparent(map.get_node("Entities"))
	var definition: Dictionary = definitions[map_id]
	player.position = spawn if spawn != Vector2.ZERO else Vector2(float(definition.spawn[0]), float(definition.spawn[1]))
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_right = int(definition.size[0]) * 16
	camera.limit_bottom = int(definition.size[1]) * 16
	camera.reset_smoothing()
	current_map_id = map_id
	EventBus.map_entered.emit(map_id)

func _add_portals(map: Node2D, map_id: String) -> void:
	var definition: Dictionary = definitions[map_id]
	var destinations: Array = definition.links.duplicate()
	destinations.append_array(definition.buildings)
	var center := Vector2(float(definition.spawn[0]), float(definition.spawn[1]))
	for index in range(destinations.size()):
		var destination: String = str(destinations[index])
		var portal := MapPortal.new()
		portal.name = "Portal_" + destination
		portal.target_map_id = destination
		portal.prompt = str(definitions[destination].name)
		portal.persistent_id = map_id + "_to_" + destination
		portal.position = center + Vector2((index % 4) * 72 - 108, 64 + (index / 4) * 48)
		if bool(definition.indoors):
			portal.position = Vector2(192, 240)
		map.get_node("Entities").add_child(portal)
	if map_id == "player_house":
		var bed := Interactable.new()
		bed.name = "Bed"
		bed.prompt = "Ngủ"
		bed.persistent_id = "player_bed"
		bed.position = Vector2(112, 96)
		bed.action = _sleep_at_bed
		map.get_node("Entities").add_child(bed)

func _sleep_at_bed() -> void:
	var minute := GameClock.model.minute_of_day()
	if minute >= 1200 or minute < 360 or player.stamina <= 0:
		if not GameClock.model.pauses.is_empty():
			return
		var dialog := ConfirmationDialog.new()
		dialog.theme = preload("res://assets/art/ui/inventory_theme.tres")
		dialog.title = "Kết thúc ngày"
		dialog.dialog_text = "Ngủ và bắt đầu ngày mới?"
		dialog.ok_button_text = "Ngủ"
		dialog.cancel_button_text = "Chưa ngủ"
		dialog.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(dialog)
		var close := func() -> void:
			EventBus.pause_requested.emit("sleep_confirmation", false)
			get_tree().paused = not GameClock.model.pauses.is_empty()
			dialog.queue_free()
		dialog.canceled.connect(close)
		dialog.confirmed.connect(func() -> void:
			close.call()
			_finish_sleep(false))
		EventBus.pause_requested.emit("sleep_confirmation", true)
		get_tree().paused = true
		dialog.popup_centered(Vector2i(260, 100))
	else:
		EventBus.notice_requested.emit("Có thể ngủ sau 20:00 hoặc khi kiệt sức")

func _forced_sleep() -> void:
	# Calendar signals may still be dispatching the old day's hour events.
	if is_instance_valid(player) and is_instance_valid(host):
		_finish_sleep.call_deferred(true)

func _finish_sleep(forced: bool) -> void:
	if not is_instance_valid(player):
		return
	var recovery := SleepRules.recovery(GameClock.model.minute_of_day())
	var loss := 0
	if forced:
		loss = SleepRules.faint_penalty(InventoryManager.coins)
		var response := {}
		EventBus.inventory_transaction_requested.emit({"coins": -loss}, response)
	EventBus.sleep_requested.emit()
	_activate("player_house", Vector2(112, 128))
	player.stamina = player.maximum_stamina() * (0.5 if forced else recovery)
	player.health = player.maximum_health() * (0.75 if forced else recovery)
	player.poison_seconds = 0.0
	player.poison_tick = 0.0
	EventBus.save_requested.emit(0)
	EventBus.notice_requested.emit("Đã được đưa về nhà: -%d Xu, hồi 50%% thể lực và 75%% HP." % loss if forced else "Ngày mới bắt đầu. Đã lưu game.")

func _save_state(state: Dictionary) -> void:
	state.scene = {"map_id": current_map_id, "flags": flags.duplicate(true)}

func _validate_state(state: Dictionary, errors: Array) -> void:
	if state.has("scene"):
		if not state.scene is Dictionary or not definitions.has(state.scene.get("map_id", "")) or not state.scene.get("flags") is Dictionary:
			errors.append("Map không hợp lệ")

func _load_state(state: Dictionary) -> void:
	var saved: Dictionary = state.get("scene", {"map_id": "farm_main", "flags": {}})
	current_map_id = str(saved.map_id)
	flags = saved.flags.duplicate(true)

func _after_restore() -> void:
	if is_instance_valid(host) and is_instance_valid(player):
		_activate(current_map_id, player.position)

func _add_navigation(map: Node2D, definition: Dictionary) -> void:
	var dimensions := Vector2(float(definition.size[0]) * 16, float(definition.size[1]) * 16)
	var region := NavigationRegion2D.new()
	var polygon := NavigationPolygon.new()
	polygon.vertices = PackedVector2Array([Vector2(12, 12), Vector2(dimensions.x - 12, 12), dimensions - Vector2(12, 12), Vector2(12, dimensions.y - 12)])
	polygon.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	region.navigation_polygon = polygon
	map.add_child(region)

func _player_fainted() -> void:
	if not is_instance_valid(player):
		return
	var penalty: int = mini(1000, floori(InventoryManager.coins * 0.1))
	var response := {}
	EventBus.inventory_transaction_requested.emit({"coins": -penalty}, response)
	player.health = player.maximum_health() * 0.75
	player.stamina = player.maximum_stamina() * 0.5
	player.poison_seconds = 0.0
	_activate("farm_main", Vector2(640, 480))
	EventBus.notice_requested.emit("Được đưa về nhà. Mất %d Xu, giữ nguyên đồ." % penalty)
