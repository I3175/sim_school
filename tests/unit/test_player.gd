extends GutTest
const PLAYER = preload("res://scenes/entities/player/player.tscn")
const FARM = preload("res://scenes/maps/farm_main.tscn")

func test_diagonal_does_not_move_faster() -> void:
	assert_almost_eq(VillagePlayer.movement_velocity(Vector2.ONE, 64.0).length(), 64.0, 0.001)
	assert_eq(VillagePlayer.movement_velocity(Vector2.ZERO, 64.0), Vector2.ZERO)

func test_animation_layers_and_snapshot_roundtrip() -> void:
	var player: VillagePlayer = add_child_autofree(PLAYER.instantiate())
	player.set_physics_process(false)
	player.position = Vector2(123, 234)
	player.stamina = 123.0
	var saved: Dictionary = JSON.parse_string(JSON.stringify(player.snapshot()))
	player.position = Vector2.ZERO
	player.restore(saved)
	assert_eq(player.position, Vector2(123, 234))
	assert_eq(player.stamina, 123.0)
	player._update_animation(Vector2.RIGHT, true)
	player.animator.advance(0.1)
	var frame: int = player.get_node("Visuals/BodySprite").frame
	for layer_name in player.LAYERS:
		var sprite: Sprite2D = player.get_node("Visuals/" + layer_name)
		assert_eq(sprite.frame, frame)
		assert_true(sprite.flip_h)
		assert_eq(sprite.texture.get_size(), Vector2(96, 96))

func test_stamina_drains_only_running_and_recovers_after_delay() -> void:
	var player: VillagePlayer = add_child_autofree(PLAYER.instantiate())
	player.set_physics_process(false)
	player._update_stamina(2.0, true, true)
	assert_eq(player.stamina, 199.0)
	player._update_stamina(14.0, false, false)
	assert_eq(player.stamina, 199.0)
	player._update_stamina(1.0, false, false)
	assert_eq(player.stamina, 200.0)

func test_farm_collision_and_camera() -> void:
	var farm: Node2D = add_child_autofree(FARM.instantiate())
	var player: VillagePlayer = farm.player
	player.set_physics_process(false)
	await get_tree().physics_frame
	assert_true(farm.get_node("Entities").y_sort_enabled)
	assert_eq(farm.get_node("Ground").get_used_cells().size(), 4800)
	player.position = Vector2(560, 450)
	assert_true(player.test_move(player.transform, Vector2(0, -20)))
	assert_eq(player.get_node("Camera2D").limit_right, 1280)
