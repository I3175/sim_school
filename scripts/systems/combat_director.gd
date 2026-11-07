extends Node
const MONSTER = preload("res://scripts/entities/monster.gd")
const PICKUP = preload("res://scripts/entities/loot_pickup.gd")
var model := CombatModel.new()
var encounters: Dictionary = {}
var drops: Dictionary = {}
var actors: Array[Node] = []
var floor_index: int = 1
var weapon_cooldown: float = 0.0
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.seed = GameClock.world_seed
	EventBus.map_entered.connect(func(_id: String) -> void: _spawn())
	EventBus.day_started.connect(_new_day)
	EventBus.monster_defeated.connect(_defeated)
	EventBus.state_save_requested.connect(_save)
	EventBus.state_load_requested.connect(_load)
	EventBus.state_restored.connect(_spawn)
	_spawn()

func _process(delta: float) -> void:
	weapon_cooldown = maxf(0.0, weapon_cooldown - delta)

func _key() -> String:
	return "%s:%d" % [SceneManager.current_map_id, floor_index if SceneManager.current_map_id == "stone_mine" else 0]

func _new_day(_day: int) -> void:
	encounters.clear()
	drops.clear()
	_spawn()

func _clear_actors() -> void:
	for actor in actors:
		if is_instance_valid(actor):
			actor.queue_free()
	actors.clear()

func _spawn() -> void:
	_clear_actors()
	var map_id := SceneManager.current_map_id
	if not SceneManager.cache.has(map_id):
		return
	var ids: Array[String] = []
	if map_id == "stone_mine":
		ids.assign(["ink_slime", "stone_worm", "paper_bat"])
	elif map_id == "whispering_forest":
		if GameClock.model.season_index() == 2 or WeatherSystem.current_weather == "fog":
			ids.append("poison_mushroom")
		if GameClock.model.minute_of_day() >= 1200 or WeatherSystem.current_weather in ["rain", "storm"]:
			ids.append("ink_slime")
	elif map_id == "golden_beach":
		if GameClock.model.minute_of_day() in range(360, 1140) and GameClock.model.minute_of_day() % 360 >= 180:
			ids.append("stone_crab")
	if ids.is_empty():
		return
	var key := _key()
	var definition: Dictionary = SceneManager.definitions[map_id]
	if not encounters.has(key):
		encounters[key] = []
		var generator := RandomNumberGenerator.new()
		generator.seed = hash("%d:%d:%s" % [GameClock.world_seed, GameClock.model.day_index(), key])
		for index in range(ids.size() * 2):
			var data: MonsterData = load("res://data/monsters/%s.tres" % ids[index % ids.size()])
			var point := Vector2.ZERO
			for attempt in range(50):
				point = Vector2(generator.randf_range(24, float(definition.size[0]) * 16 - 24), generator.randf_range(24, float(definition.size[1]) * 16 - 24))
				if point.distance_to(SceneManager.player.position) >= 192:
					break
			var scale_floor := floor_index - 1 if map_id == "stone_mine" else 0
			var hp := data.health * (1.0 + float(model.rules.hp_per_floor) * scale_floor)
			encounters[key].append({"id": "%s_%d" % [key, index], "type": data.id, "x": point.x, "y": point.y, "spawn_x": point.x, "spawn_y": point.y, "health": hp, "max_health": hp, "attack": data.attack * (1.0 + float(model.rules.attack_per_floor) * scale_floor), "dead": false})
	for record: Dictionary in encounters[key]:
		if record.dead:
			continue
		var monster := CharacterBody2D.new()
		monster.set_script(MONSTER)
		monster.definition = load("res://data/monsters/%s.tres" % str(record.type))
		monster.record = record
		SceneManager.cache[map_id].get_node("Entities").add_child(monster)
		actors.append(monster)
	for drop: Dictionary in drops.get(key, []):
		if not drop.collected:
			_add_pickup(drop)

func _defeated(persistent_id: String, monster_id: String, location: Vector2) -> void:
	var definition: MonsterData = load("res://data/monsters/%s.tres" % monster_id)
	var xp := model.experience(definition, SceneManager.player.resident_level)
	EventBus.resident_xp_awarded.emit(xp)
	EventBus.combat_xp_awarded.emit(roundi(xp * float(model.rules.combat_xp_ratio)))
	EventBus.monster_killed.emit(monster_id, 0)
	var loot := model.roll_loot(definition, hash("%d:%s:%d" % [GameClock.world_seed, persistent_id, GameClock.model.day_index()]))
	if not drops.has(_key()):
		drops[_key()] = []
	for item: Dictionary in loot:
		var drop := {"item": item, "x": location.x, "y": location.y, "collected": false}
		drops[_key()].append(drop)
		_add_pickup(drop)

func _add_pickup(record: Dictionary) -> void:
	var pickup := Node2D.new()
	pickup.set_script(PICKUP)
	pickup.record = record
	SceneManager.cache[SceneManager.current_map_id].get_node("Entities").add_child(pickup)
	actors.append(pickup)

func _unhandled_input(event: InputEvent) -> void:
	var attack: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J
	attack = attack or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not attack or weapon_cooldown > 0 or not is_instance_valid(SceneManager.player):
		return
	var slot: Dictionary = InventoryManager.bag.slots[InventoryManager.selected_slot]
	if slot.is_empty() or not model.rules.weapons.has(slot.id):
		return
	var player: VillagePlayer = SceneManager.player
	if not player.input_enabled or player.stamina < float(model.rules.attack_cost):
		return
	var weapon: Dictionary = model.rules.weapons[slot.id]
	weapon_cooldown = float(weapon.cooldown)
	player.stamina -= float(model.rules.attack_cost)
	var facing := Vector2.DOWN if player.direction_index == 0 else Vector2.UP
	if player.direction_index == 2:
		facing = Vector2.RIGHT if player.facing_right else Vector2.LEFT
	for monster in get_tree().get_nodes_in_group("monsters"):
		if model.in_attack_arc(player.position, facing, monster.position, float(weapon.range), float(weapon.arc_degrees)):
			monster.hit(float(model.rules.base_attack) + float(weapon.attack), random.randf() < float(model.rules.critical_chance), random.randf_range(float(model.rules.variance_min), float(model.rules.variance_max)), str(slot.id))
	get_viewport().set_input_as_handled()

func _save(state: Dictionary) -> void:
	state.combat = {"encounters": encounters.duplicate(true), "drops": drops.duplicate(true), "floor": floor_index}

func _load(state: Dictionary) -> void:
	var saved: Dictionary = state.get("combat", {})
	encounters = saved.get("encounters", {}).duplicate(true)
	drops = saved.get("drops", {}).duplicate(true)
	floor_index = clampi(int(saved.get("floor", 1)), 1, 40)
