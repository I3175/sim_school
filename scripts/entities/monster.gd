extends CharacterBody2D
var definition: MonsterData
var record: Dictionary
var model := CombatModel.new()
var state: String = "Idle"
var timer: float = 0.0
var hurt_timer: float = 0.0
var hp_bar_timer: float = 0.0
var agent: NavigationAgent2D
var attack_origin: Vector2
var spawn_position: Vector2

func _ready() -> void:
	add_to_group("monsters")
	collision_layer = 8
	collision_mask = 1
	spawn_position = Vector2(float(record.spawn_x), float(record.spawn_y))
	position = Vector2(float(record.x), float(record.y))
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5
	collision.shape = shape
	add_child(collision)
	agent = NavigationAgent2D.new()
	agent.path_desired_distance = 3.0
	agent.target_desired_distance = 3.0
	add_child(agent)

func _physics_process(delta: float) -> void:
	timer = maxf(0.0, timer - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	hp_bar_timer = maxf(0.0, hp_bar_timer - delta)
	queue_redraw()
	if state == "Dead":
		modulate.a = timer / float(model.rules.death_seconds)
		if timer <= 0:
			queue_free()
		return
	var player := get_tree().get_first_node_in_group("player") as VillagePlayer
	if player == null:
		return
	var distance := position.distance_to(player.position)
	if position.distance_to(spawn_position) > float(model.rules.leash_radius):
		state = "Return"
	if state == "Return":
		_move_to(spawn_position)
		record.health = minf(float(record.max_health), float(record.health) + float(record.max_health) * 0.05 * delta)
		if position.distance_to(spawn_position) < 8:
			state = "Idle"
	elif state == "Idle" and distance <= float(model.rules.detection_radius):
		state = "Alert"
		timer = float(model.rules.alert_seconds)
	elif state == "Alert" and timer <= 0:
		state = "Chase"
	elif state == "Chase":
		var reach: float = 40.0 if definition.behavior == "spore" else 24.0
		if distance <= reach:
			state = "Telegraph"
			timer = definition.telegraph
			attack_origin = player.position
		elif definition.behavior != "spore":
			_move_to(player.position)
		if distance > float(model.rules.detection_radius) * 1.5:
			state = "Return"
	elif state == "Telegraph" and timer <= 0:
		state = "Recover"
		timer = 3.0 if definition.behavior == "spore" else float(model.rules.recover_seconds)
		if definition.behavior == "leap":
			move_and_collide(position.direction_to(attack_origin) * 32.0)
		if position.distance_to(player.position) <= (40.0 if definition.behavior == "spore" else 24.0):
			EventBus.player_damage_requested.emit(model.damage(float(record.attack), float(model.rules.base_defense)), "poison" if definition.behavior == "spore" else "")
	elif state == "Recover" and timer <= 0:
		state = "Chase"
	record.x = position.x
	record.y = position.y

func _move_to(target: Vector2) -> void:
	if NavigationServer2D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	agent.target_position = target
	var direction := position.direction_to(agent.get_next_path_position())
	if definition.behavior == "zigzag":
		direction = direction.rotated(sin(float(Time.get_ticks_msec()) * 0.008) * 0.4)
	velocity = direction * definition.speed
	move_and_slide()

func hit(attack: float, critical: bool, variance: float, weapon: String) -> void:
	if state == "Dead" or (definition.behavior == "burrow" and state == "Telegraph"):
		return
	var defense := definition.defense
	if definition.behavior == "claw" and state == "Recover" and weapon != "hammer":
		defense += 10.0
	record.health = maxf(0.0, float(record.health) - model.damage(attack, defense, variance, critical))
	hurt_timer = 0.1
	hp_bar_timer = 4.0
	if float(record.health) == 0:
		record.dead = true
		state = "Dead"
		timer = float(model.rules.death_seconds)
		collision_layer = 0
		EventBus.monster_defeated.emit(str(record.id), definition.id, position)

func _draw() -> void:
	var colors := {"leap": Color("66569b"), "burrow": Color("8d806f"), "zigzag": Color("bdb6c8"), "spore": Color("a26da2"), "claw": Color("888d9d")}
	var tint: Color = Color.WHITE if hurt_timer > 0 else colors[definition.behavior]
	draw_rect(Rect2(-7, -14, 14, 14), tint)
	draw_rect(Rect2(-4, -10, 2, 2), Color("303044"))
	draw_rect(Rect2(2, -10, 2, 2), Color("303044"))
	if state == "Telegraph":
		draw_arc(Vector2.ZERO, 40 if definition.behavior == "spore" else 20, 0, TAU, 24, Color(1, 0.3, 0.2, 0.8), 1)
	if hp_bar_timer > 0:
		draw_rect(Rect2(-8, -19, 16, 2), Color("342c3f"))
		draw_rect(Rect2(-8, -19, 16 * float(record.health) / float(record.max_health), 2), Color("d88870"))
