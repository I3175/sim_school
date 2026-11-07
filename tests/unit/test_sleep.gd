extends GutTest

func test_midnight_recovery_boundaries() -> void:
	assert_eq(SleepRules.recovery(1200), 1.0)
	assert_eq(SleepRules.recovery(1439), 1.0)
	assert_eq(SleepRules.recovery(0), 1.0)
	assert_eq(SleepRules.recovery(9), 1.0)
	assert_almost_eq(SleepRules.recovery(10), 0.95, 0.0001)
	assert_eq(SleepRules.recovery(60), 0.7)
	assert_eq(SleepRules.recovery(119), 0.7)
	assert_eq(SleepRules.recovery(1500), 0.7)
	assert_eq(SleepRules.recovery(360), 1.0)

func test_forced_sleep_loss_has_a_separate_cap_from_combat_fainting() -> void:
	assert_eq(SleepRules.faint_penalty(0), 0)
	assert_eq(SleepRules.faint_penalty(500), 25)
	assert_eq(SleepRules.faint_penalty(999), 49)
	assert_eq(SleepRules.faint_penalty(10000), 500)
	assert_eq(SleepRules.faint_penalty(100000), 500)

func test_two_am_returns_home_advances_day_and_autosaves_recovered_state() -> void:
	var previous := {"maps": {}}
	EventBus.state_save_requested.emit(previous)
	var directory: String = SaveManager.store.directory
	SaveManager.store.directory = "user://sleep_test_%d" % Time.get_ticks_usec()
	var boot: Node = load("res://scenes/core/boot.tscn").instantiate()
	add_child(boot)
	var player: VillagePlayer = SceneManager.player
	player.set_physics_process(false)
	player.set_process(false)
	GameClock.model.total_minutes = 1559
	GameClock.model.awaiting_sleep = false
	GameClock.model.pauses.clear()
	InventoryManager.coins = 1000
	player.poison_seconds = 12
	GameClock.advance(20.0)
	await get_tree().process_frame
	assert_eq(GameClock.model.day_index(), 1)
	assert_eq(SceneManager.current_map_id, "player_house")
	assert_eq(InventoryManager.coins, 950)
	assert_eq(player.stamina, player.maximum_stamina() * 0.5)
	assert_eq(player.health, player.maximum_health() * 0.75)
	assert_eq(player.poison_seconds, 0.0)
	var saved := SaveManager.store.read_slot(0)
	assert_eq(int(saved.inventory.coins), 950)
	assert_eq(saved.scene.map_id, "player_house")
	assert_true(saved.story.facts.get("sleep:", false))
	boot.free()
	EventBus.state_load_requested.emit(previous)
	EventBus.state_restored.emit()
	for filename: String in DirAccess.get_files_at(SaveManager.store.directory):
		DirAccess.remove_absolute(SaveManager.store.directory + "/" + filename)
	DirAccess.remove_absolute(SaveManager.store.directory)
	SaveManager.store.directory = directory
