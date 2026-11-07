extends GutTest
func test_rain_schedule_and_once_daily_friendship() -> void:
	var social := SocialModel.new()
	assert_eq(social.activity("di_nam", 1, 400, "sunny").map_id, "market_street")
	assert_eq(social.activity("di_nam", 1, 400, "rain").map_id, "grocery")
	assert_eq(social.activity("di_nam", 6, 600, "sunny").map_id, "town_square")
	assert_true(social.talk("di_nam", 0))
	assert_false(social.talk("di_nam", 0))
	assert_eq(social.friendships.di_nam, 20)
	assert_true(social.gift("di_nam", "crop_greens", 0))
	assert_false(social.gift("di_nam", "crop_greens", 0))
	assert_eq(social.friendships.di_nam, 40)

func test_dialogue_manager_parses_and_branches() -> void:
	var resource: Resource = DialogueManager.create_resource_from_text(FileAccess.get_file_as_string("res://data/npcs/di_nam.dialogue.txt"))
	var line = await DialogueManager.get_next_dialogue_line(resource, "start")
	assert_eq(line.character, "Dì Năm")
	assert_eq(line.responses.size(), 2)
	var next = await DialogueManager.get_next_dialogue_line(resource, line.responses[0].next_id)
	assert_string_contains(next.text, "quảng trường")

func test_purchase_transaction_never_charges_when_bag_full() -> void:
	var previous := {}
	InventoryManager._collect_state(previous)
	for index in range(InventoryManager.bag.slots.size()):
		InventoryManager.bag.slots[index] = {"id": "wood", "amount": 999, "quality": 0}
	InventoryManager.coins = 100
	var response := {}
	EventBus.inventory_transaction_requested.emit({"add": [{"id": "seed_greens", "amount": 1}], "coins": -20}, response)
	assert_false(response.success)
	assert_eq(InventoryManager.coins, 100)
	InventoryManager.bag.slots[0] = {}
	EventBus.inventory_transaction_requested.emit({"add": [{"id": "seed_greens", "amount": 1}], "coins": -20}, response)
	assert_true(response.success)
	assert_eq(InventoryManager.coins, 80)
	InventoryManager._load_state(previous)
