extends GutTest
func test_opening_hours_overnight_and_unlock() -> void:
	assert_true(MapRules.available({"opening": 1140, "closing": 120}, 60, 1, {}))
	assert_false(MapRules.available({"opening": 1140, "closing": 120}, 120, 1, {}))
	assert_false(MapRules.available({"opening": 540, "closing": 1140}, 500, 1, {}))
	assert_false(MapRules.available({"required_flag": "chapter_1"}, 600, 1, {}))
	assert_true(MapRules.available({"required_flag": "chapter_1"}, 600, 1, {"chapter_1": true}))

func test_all_maps_build_and_farm_cache_preserves_crops() -> void:
	var main: Node = add_child_autofree(load("res://scenes/core/boot.tscn").instantiate())
	SceneManager.player.set_physics_process(false)
	var field: Node = SceneManager.cache.farm_main.get_node("FarmingField")
	field.model.till("39,34")
	field.model.plant("39,34", "greens", 0)
	for map_id: String in SceneManager.definitions:
		SceneManager._activate(map_id, Vector2.ZERO)
		assert_eq(SceneManager.current_map_id, map_id)
		assert_true(SceneManager.player.get_parent().y_sort_enabled)
	SceneManager._activate("farm_main", Vector2(640, 480))
	assert_eq(SceneManager.cache.farm_main.get_node("FarmingField").model.cells["39,34"].crop, "greens")
	assert_eq(SceneManager.cache.size(), SceneManager.definitions.size())
	main.queue_free()
	await get_tree().process_frame
