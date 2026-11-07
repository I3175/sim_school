extends GutTest
func test_three_day_greens_cycle_and_no_duplicate_day() -> void:
	var farm := FarmingModel.new()
	assert_true(farm.till("1,1"))
	assert_true(farm.plant("1,1", "greens", 0))
	farm.water("1,1")
	farm.advance_day(1, 0, false)
	assert_false(farm.mature("1,1"))
	farm.water("1,1")
	farm.advance_day(2, 0, false)
	assert_true(farm.mature("1,1"))
	var harvest := farm.harvest("1,1")
	assert_eq(harvest.id, "crop_greens")
	assert_eq(farm.farming_xp, 4)
	assert_eq(farm.harvest("1,1"), {})
	farm.advance_day(2, 0, false)
	assert_eq(farm.last_day, 2)

func test_drought_rain_regrowth_and_season_change() -> void:
	var farm := FarmingModel.new()
	farm.till("1,1")
	farm.plant("1,1", "greens", 0)
	for index in range(1, 4):
		farm.advance_day(index, 0, false)
	assert_true(farm.cells["1,1"].withered)
	farm.till("2,2")
	farm.plant("2,2", "strawberry", 0)
	for index in range(4, 9):
		farm.rain()
		farm.advance_day(index, 0, true)
	assert_true(farm.mature("2,2"))
	farm.harvest("2,2")
	assert_false(farm.mature("2,2"))
	farm.advance_day(9, 1, false)
	assert_true(farm.cells["2,2"].withered)

func test_wrong_season_and_greenhouse_exception() -> void:
	var farm := FarmingModel.new()
	farm.till("1,1")
	assert_false(farm.plant("1,1", "tomato", 0))
	assert_true(farm.plant("1,1", "tomato", 0, true))
	farm.water("1,1")
	farm.advance_day(1, 3, false)
	assert_false(farm.cells["1,1"].withered)
	var restored := FarmingModel.new()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(farm.snapshot()))
	assert_true(restored.valid_snapshot(saved))
	restored.restore(saved)
	assert_eq(restored.cells, farm.cells)

func test_live_three_day_plant_harvest_ship_and_reload() -> void:
	var farm: Node2D = add_child_autofree(load("res://scenes/maps/farm_main.tscn").instantiate())
	farm.player.set_physics_process(false)
	var field := farm.get_node("FarmingField")
	var original_inventory := {}
	InventoryManager._collect_state(original_inventory)
	var original_clock := GameClock.snapshot()
	GameClock.model.total_minutes = 360.0
	GameClock.model.awaiting_sleep = false
	field.model.last_day = 0
	field.model.till("39,34")
	field.model.plant("39,34", "greens", 0)
	field.model.water("39,34")
	EventBus.sleep_requested.emit()
	field.model.water("39,34")
	EventBus.sleep_requested.emit()
	var before_count: int = InventoryManager.bag.count("crop_greens")
	field._harvest("39,34")
	assert_eq(InventoryManager.bag.count("crop_greens"), before_count + 1)
	var selected := -1
	for index in range(InventoryManager.bag.slots.size()):
		if InventoryManager.bag.slots[index].get("id", "") == "crop_greens":
			selected = index
	assert_gte(selected, 0)
	InventoryManager.selected_slot = selected
	var coins_before: int = InventoryManager.coins
	field._ship_selected()
	EventBus.sleep_requested.emit()
	assert_gt(InventoryManager.coins, coins_before)
	var after_income: int = InventoryManager.coins
	var saved := {"maps": {}}
	EventBus.state_save_requested.emit(saved)
	EventBus.state_load_requested.emit(saved)
	EventBus.state_restored.emit()
	assert_eq(InventoryManager.coins, after_income)
	assert_eq(field.model.shipping.size(), 0)
	InventoryManager._load_state(original_inventory)
	GameClock.restore(original_clock)
