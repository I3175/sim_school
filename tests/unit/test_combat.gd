extends GutTest
func test_damage_scaling_minimum_and_arc() -> void:
	var model := CombatModel.new()
	assert_eq(model.damage(10, 100), 5)
	assert_eq(model.damage(0, 999), 1)
	assert_eq(model.damage(10, 0, 1.0, true), 15)
	assert_true(model.in_attack_arc(Vector2.ZERO, Vector2.RIGHT, Vector2(16, 0), 24, 90))
	assert_false(model.in_attack_arc(Vector2.ZERO, Vector2.RIGHT, Vector2(-16, 0), 24, 90))
	assert_false(model.in_attack_arc(Vector2.ZERO, Vector2.RIGHT, Vector2(40, 0), 24, 360))

func test_all_five_monsters_xp_and_seeded_loot() -> void:
	var model := CombatModel.new()
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/monsters/catalog.json"))
	assert_eq(catalog.size(), 5)
	for id: String in catalog:
		var monster: MonsterData = load("res://data/monsters/%s.tres" % id)
		assert_gt(model.experience(monster, 1), 0)
		assert_eq(model.roll_loot(monster, 42), model.roll_loot(monster, 42))
		assert_gte(model.experience(monster, 30), roundi(monster.base_xp * 0.25))

func test_player_invulnerability_and_xp_level() -> void:
	var player: VillagePlayer = add_child_autofree(load("res://scenes/entities/player/player.tscn").instantiate())
	player.set_physics_process(false)
	player.take_damage(10)
	player.take_damage(10)
	assert_eq(player.health, 90.0)
	player._update_health(0.6)
	player.take_damage(10)
	assert_eq(player.health, 80.0)
	player.award_xp(130)
	assert_eq(player.resident_level, 2)
	assert_eq(player.maximum_health(), 105.0)
	assert_eq(player.maximum_stamina(), 203.0)
