class_name VillagePlayer
extends CharacterBody2D

const BALANCE_PATH := "res://data/balance/player.json"
const LAYERS: Array[String] = ["ShadowSprite", "BodySprite", "BottomSprite", "ShoesSprite", "TopSprite", "EyesSprite", "HairSprite"]
var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BALANCE_PATH))
var stamina: float = float(balance.stamina_max)
var direction_index: int = 0
var facing_right: bool = false
var current_state: String = "idle"
var idle_seconds: float = 0.0
var recovery_seconds: float = 0.0
var input_enabled: bool = true
var resident_xp: int = 0
var resident_level: int = 1
var health: float = 100.0
var combat_xp: int = 0
var hurt_cooldown: float = 0.0
var no_damage_seconds: float = 0.0
var regeneration_seconds: float = 0.0
var poison_seconds: float = 0.0
var poison_tick: float = 0.0
var combat_rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/combat.json"))
@onready var animator: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	EventBus.player_damage_requested.connect(take_damage)
	EventBus.combat_xp_awarded.connect(func(amount: int) -> void: combat_xp += amount)
	EventBus.resident_xp_awarded.connect(award_xp)
	EventBus.state_save_requested.connect(func(state: Dictionary) -> void: state.player = snapshot())
	EventBus.state_validate_requested.connect(_validate_saved_player)
	EventBus.state_load_requested.connect(func(state: Dictionary) -> void: restore(state.player))
	_create_animations()
	_update_animation(Vector2.ZERO, false)

static func movement_velocity(direction: Vector2, speed: float) -> Vector2:
	return direction.limit_length() * speed

func _physics_process(delta: float) -> void:
	_update_health(delta)
	var direction := Vector2.ZERO
	if input_enabled:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running: bool = input_enabled and Input.is_action_pressed("run") and stamina > 0.0 and direction != Vector2.ZERO
	var speed: float = float(balance.run_speed if running else balance.walk_speed)
	if stamina <= 0.0:
		speed *= float(balance.exhausted_multiplier)
	velocity = movement_velocity(direction, speed)
	move_and_slide()
	_update_stamina(delta, running, direction != Vector2.ZERO)
	_update_animation(direction, running)

func _update_stamina(delta: float, running: bool, moving: bool) -> void:
	if running:
		stamina = maxf(0.0, stamina - float(balance.run_cost_per_second) * delta)
	if moving:
		idle_seconds = 0.0
		recovery_seconds = 0.0
	else:
		var previous_idle: float = idle_seconds
		idle_seconds += delta
		recovery_seconds += maxf(0.0, idle_seconds - maxf(previous_idle, float(balance.idle_recovery_delay)))
		while recovery_seconds >= float(balance.recovery_interval):
			recovery_seconds -= float(balance.recovery_interval)
			stamina = minf(maximum_stamina(), stamina + float(balance.recovery_amount))

func _update_animation(direction: Vector2, running: bool) -> void:
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			direction_index = 2
			facing_right = direction.x > 0.0
		else:
			direction_index = 0 if direction.y > 0.0 else 1
			facing_right = false
	current_state = "idle" if direction == Vector2.ZERO else ("run" if running else "walk")
	for layer_name in LAYERS:
		var sprite: Sprite2D = $Visuals.get_node(layer_name)
		sprite.flip_h = facing_right
	var facing := Vector2.DOWN if direction_index == 0 else Vector2.UP
	if direction_index == 2:
		facing = Vector2.RIGHT if facing_right else Vector2.LEFT
	$InteractionDetector.position = facing * 16.0
	var animation_name := "%s_%s" % [current_state, direction_index]
	if animator.current_animation != animation_name:
		animator.play(animation_name)

func _create_animations() -> void:
	var library := AnimationLibrary.new()
	for state: String in ["idle", "walk", "run"]:
		var frames: Array = [0, 3] if state == "idle" else [0, 1, 2, 3, 4, 5]
		var fps: float = 2.0 if state == "idle" else (10.0 if state == "walk" else 14.0)
		for direction in range(3):
			var animation := Animation.new()
			animation.length = frames.size() / fps
			animation.loop_mode = Animation.LOOP_LINEAR
			for layer_name in LAYERS:
				var track := animation.add_track(Animation.TYPE_VALUE)
				animation.track_set_path(track, NodePath("Visuals/%s:frame" % layer_name))
				animation.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
				for index in range(frames.size()):
					animation.track_insert_key(track, index / fps, direction * 6 + int(frames[index]))
			library.add_animation("%s_%s" % [state, direction], animation)
	animator.add_animation_library("", library)

func snapshot() -> Dictionary:
	return {"x": position.x, "y": position.y, "stamina": stamina, "direction": direction_index, "facing_right": facing_right, "resident_xp": resident_xp, "health": health, "combat_xp": combat_xp}

func restore(state: Dictionary) -> void:
	combat_xp = maxi(0, int(state.get("combat_xp", 0)))
	resident_xp = maxi(0, int(state.get("resident_xp", 0)))
	resident_level = level_for_xp(resident_xp)
	health = clampf(float(state.get("health", 100)), 0.0, maximum_health())
	position = Vector2(float(state.get("x", position.x)), float(state.get("y", position.y)))
	stamina = clampf(float(state.get("stamina", stamina)), 0.0, maximum_stamina())
	direction_index = clampi(int(state.get("direction", 0)), 0, 2)
	facing_right = bool(state.get("facing_right", false))

func _validate_saved_player(state: Dictionary, errors: Array) -> void:
	var saved: Variant = state.get("player")
	if not saved is Dictionary:
		errors.append("Nhân vật không hợp lệ")
		return
	for field: String in ["x", "y", "stamina", "direction"]:
		if not (saved.get(field) is int or saved.get(field) is float) or not is_finite(float(saved.get(field, 0))):
			errors.append("Chỉ số nhân vật không hợp lệ")

func _unhandled_key_input(event: InputEvent) -> void:
	if not input_enabled or not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_E:
		return
	var candidates: Array[Area2D] = $InteractionDetector.get_overlapping_areas()
	candidates = candidates.filter(func(area: Area2D) -> bool: return area is Interactable)
	candidates.sort_custom(func(a: Area2D, b: Area2D) -> bool:
		if a.interaction_priority != b.interaction_priority:
			return a.interaction_priority > b.interaction_priority
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	if not candidates.is_empty():
		candidates[0].interact()
		get_viewport().set_input_as_handled()

func level_for_xp(total: int) -> int:
	var level := 1
	var remaining := total
	while level < int(balance.resident_max_level):
		var cost: int = int(balance.xp_base) + int(balance.xp_linear) * level + int(balance.xp_quadratic) * level * level
		if remaining < cost:
			break
		remaining -= cost
		level += 1
	return level

func maximum_stamina() -> float:
	return float(balance.stamina_max) + (resident_level - 1) * float(balance.stamina_per_level)

func maximum_health() -> float:
	return float(balance.health_base) + (resident_level - 1) * float(balance.health_per_level)

func award_xp(amount: int) -> void:
	var previous_level := resident_level
	resident_xp += maxi(0, amount)
	resident_level = level_for_xp(resident_xp)
	if resident_level > previous_level:
		stamina = maximum_stamina()
		health = maximum_health()
		EventBus.notice_requested.emit("Cấp Cư Dân %d" % resident_level)

func take_damage(amount: int, status: String = "") -> void:
	if hurt_cooldown > 0 or health <= 0:
		return
	health = maxf(0.0, health - maxi(1, amount))
	hurt_cooldown = float(combat_rules.invulnerability)
	no_damage_seconds = 0.0
	regeneration_seconds = 0.0
	if status == "poison":
		poison_seconds = 12.0
		poison_tick = 0.0
	if health <= 0:
		EventBus.player_fainted.emit()

func _update_health(delta: float) -> void:
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	no_damage_seconds += delta
	if no_damage_seconds >= float(combat_rules.regeneration_delay):
		regeneration_seconds += delta
		if regeneration_seconds >= float(combat_rules.regeneration_interval):
			regeneration_seconds -= float(combat_rules.regeneration_interval)
			health = minf(maximum_health(), health + 1)
	if poison_seconds > 0:
		poison_seconds -= delta
		poison_tick += delta
		if poison_tick >= 2.0:
			poison_tick -= 2.0
			take_damage(1)
	$Visuals.modulate = Color(1, 1, 1, 0.5 if hurt_cooldown > 0 else 1.0)
