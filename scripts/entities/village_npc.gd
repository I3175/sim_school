extends CharacterBody2D
var npc_id: String = ""
var destination: Vector2
var speed: float = 32.0
var agent: NavigationAgent2D
var animation_time: float = 0.0
var layers: Array[Sprite2D] = []
func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8, 5)
	collision.shape = shape
	add_child(collision)
	for layer: String in ["shadow", "body", "bottom", "shoes", "top", "eyes", "hair"]:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/art/characters/prototype/%s.svg" % layer)
		sprite.hframes = 6
		sprite.vframes = 3
		sprite.position.y = -14
		if layer == "top":
			sprite.modulate = Color.from_hsv(float(abs(npc_id.hash()) % 100) / 100.0, 0.35, 1.0)
		add_child(sprite)
		layers.append(sprite)
	agent = NavigationAgent2D.new()
	agent.path_desired_distance = 2.0
	agent.target_desired_distance = 2.0
	add_child(agent)
	agent.target_position = destination
	var interaction := Interactable.new()
	interaction.prompt = str(JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs/catalog.json"))[npc_id].name)
	interaction.persistent_id = npc_id
	interaction.interaction_priority = 3
	interaction.action = func() -> void: EventBus.npc_talk_requested.emit(npc_id)
	add_child(interaction)

func _physics_process(delta: float) -> void:
	if NavigationServer2D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	agent.target_position = destination
	var direction := Vector2.ZERO
	if position.distance_to(destination) > 2.0 and not agent.is_navigation_finished():
		direction = global_position.direction_to(agent.get_next_path_position())
	velocity = direction * speed
	move_and_slide()
	animation_time += delta
	var row := 0 if direction.y >= 0 else 1
	if absf(direction.x) > absf(direction.y):
		row = 2
	var frame := int(animation_time * 10.0) % 6 if direction != Vector2.ZERO else 0
	for sprite: Sprite2D in layers:
		sprite.frame = row * 6 + frame
		sprite.flip_h = row == 2 and direction.x > 0
