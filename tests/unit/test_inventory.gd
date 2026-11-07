extends GutTest
func test_stack_limits_partial_add_and_quality() -> void:
	var bag := InventoryModel.new(ItemDatabase.items, 2)
	assert_eq(bag.add("crop_greens", 250), 52)
	assert_eq(bag.count("crop_greens"), 198)
	assert_eq(bag.add("crop_greens", 1, 1), 1)
	assert_eq(bag.add("unknown", 3), 3)
	assert_eq(bag.add("wood", 1, 2), 1)

func test_split_merge_swap_and_self_drop_preserve_count() -> void:
	var bag := InventoryModel.new(ItemDatabase.items, 3)
	var chest := InventoryModel.new(ItemDatabase.items, 3)
	bag.add("wood", 100)
	chest.add("stone", 10)
	assert_false(bag.move_to(0, bag, 0))
	assert_false(bag.move_to(0, chest, 0, 50))
	assert_true(bag.move_to(0, chest, 1, 50))
	assert_eq(bag.count("wood") + chest.count("wood"), 100)
	assert_true(bag.move_to(0, chest, 1))
	assert_eq(chest.count("wood"), 100)
	assert_true(chest.move_to(0, chest, 1))
	assert_eq(chest.count("stone"), 10)

func test_invalid_restore_is_atomic_and_removal_is_atomic() -> void:
	var bag := InventoryModel.new(ItemDatabase.items, 2)
	bag.add("wood", 10)
	var before := bag.slots.duplicate(true)
	assert_false(bag.restore([{"id": "wood", "amount": 1000, "quality": 0}, {}]))
	assert_eq(bag.slots, before)
	assert_false(bag.remove("wood", 11))
	assert_eq(bag.slots, before)
	assert_true(bag.remove("wood", 10))
	assert_eq(bag.count("wood"), 0)

func test_save_store_roundtrip_and_corruption() -> void:
	var store := SaveStore.new()
	store.directory = "user://test_saves_%d" % Time.get_ticks_usec()
	assert_true(store.write_slot(0, {"inventory": {"coins": 123}}))
	assert_eq(int(store.read_slot(0).inventory.coins), 123)
	assert_true(store.write_slot(0, {"inventory": {"coins": 456}}))
	assert_true(FileAccess.file_exists(store.directory + "/slot_0.json.bak"))
	assert_false(store.write_slot(3, {}))
	var file := FileAccess.open(store.directory + "/slot_0.json", FileAccess.WRITE)
	file.store_string("broken json")
	file.close()
	assert_eq(store.read_slot(0), {})
	for filename: String in DirAccess.get_files_at(store.directory):
		DirAccess.remove_absolute(store.directory + "/" + filename)
	DirAccess.remove_absolute(store.directory)

func test_full_save_load_and_bad_inventory_does_not_mutate_world() -> void:
	var farm: Node2D = add_child_autofree(load("res://scenes/maps/farm_main.tscn").instantiate())
	farm.player.set_physics_process(false)
	var original_directory: String = SaveManager.store.directory
	SaveManager.store.directory = "user://integration_saves_%d" % Time.get_ticks_usec()
	var previous_clock := GameClock.snapshot()
	var previous_inventory := {}
	InventoryManager._collect_state(previous_inventory)
	farm.player.position = Vector2(640, 480)
	InventoryManager.coins = 321
	assert_true(SaveManager.save_slot(1))
	farm.player.position = Vector2(700, 500)
	InventoryManager.coins = 10
	assert_true(SaveManager.load_slot(1))
	assert_eq(farm.player.position, Vector2(640, 480))
	assert_eq(InventoryManager.coins, 321)
	var damaged: Dictionary = SaveManager.store.read_slot(1)
	damaged.inventory.bag[0].amount = -5
	damaged.player.x = 900
	assert_true(SaveManager.store.write_slot(1, damaged))
	assert_false(SaveManager.load_slot(1))
	assert_eq(farm.player.position, Vector2(640, 480))
	assert_eq(InventoryManager.coins, 321)
	for filename: String in DirAccess.get_files_at(SaveManager.store.directory):
		DirAccess.remove_absolute(SaveManager.store.directory + "/" + filename)
	DirAccess.remove_absolute(SaveManager.store.directory)
	SaveManager.store.directory = original_directory
	GameClock.restore(previous_clock)
	InventoryManager._load_state(previous_inventory)
