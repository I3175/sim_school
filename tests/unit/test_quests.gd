extends GutTest
func test_all_eight_types_accept_complete_claim_exactly_once() -> void:
	var model := QuestModel.new()
	model.refresh({"day": 6, "flags": {"chapter_1": true}, "friendships": {"di_nam": 200}, "discovered": ["library_hill"]})
	var types: Dictionary = {}
	for id: String in model.definitions:
		var quest: QuestData = model.definitions[id]
		types[quest.quest_type] = true
		assert_true(model.accept(id, 6), id)
		assert_false(model.accept(id, 6))
		for objective: Dictionary in quest.objectives:
			model.record(str(objective.type), str(objective.target), int(objective.amount))
		assert_eq(model.states[id].status, "Ready")
		assert_false(model.claim(id, 6).is_empty())
		assert_true(model.claim(id, 6).is_empty())
	assert_eq(types.size(), 8)

func test_expiry_repeat_and_hidden_prerequisite() -> void:
	var model := QuestModel.new()
	model.refresh({"day": 1, "flags": {"chapter_1": true}})
	assert_eq(model.states.old_library.status, "Locked")
	model.accept("daily_greens", 1)
	model.accept("first_harvest", 1)
	model.refresh({"day": 2, "flags": {"chapter_1": true}})
	assert_eq(model.states.daily_greens.status, "Available")
	assert_eq(model.states.first_harvest.status, "Active")
	model.refresh({"day": 2, "discovered": ["library_hill"]})
	assert_eq(model.states.old_library.status, "Available")
