extends GutTest

func test_combat_phase_cannot_be_skipped_by_attacking() -> void:
	var model := ZeroEncounterModel.new()
	model.position = ZeroEncounterModel.TARGETS[1]
	assert_eq(model.attack().result, "unavailable")
	for index in range(121): model.tick(0.05, Vector2.RIGHT)
	assert_eq(model.phase, "answer")
	model.position = Vector2(152, 140)
	assert_eq(model.attack().result, "out_of_range")
	model.position = ZeroEncounterModel.TARGETS[1]
	assert_eq(model.attack().result, "cracked")
	assert_eq(model.phase, "dodge")
	assert_eq(model.attack().result, "unavailable")

func test_three_puzzles_required_and_help_after_three_mistakes() -> void:
	var model := ZeroEncounterModel.new()
	model.phase = "answer"
	model.position = ZeroEncounterModel.TARGETS[0]
	for index in range(3): assert_eq(model.attack().result, "wrong")
	assert_eq(model.round_index, 0)
	assert_true(model.hint().contains("12"))
	for round_index in range(3):
		model.phase = "answer"
		model.position = ZeroEncounterModel.TARGETS[int(model.rules.rounds[round_index].correct)]
		assert_eq(model.attack().result, "won" if round_index == 2 else "cracked")
	assert_eq(model.phase, "won")
	assert_eq(model.attack().result, "unavailable")
	assert_eq(model.tick(10, Vector2.ZERO), 0)

func test_telegraphed_fall_can_be_evaded_and_only_hits_once() -> void:
	var model := ZeroEncounterModel.new()
	model.hazards.append({"center": model.position, "age": 0.0, "hit": false})
	assert_eq(model.tick(0.5, Vector2.ZERO), 0)
	assert_eq(model.tick(0.21, Vector2.ZERO), 10)
	assert_eq(model.tick(0.01, Vector2.ZERO), 0)
	model = ZeroEncounterModel.new()
	model.hazards.append({"center": model.position, "age": 0.0, "hit": false})
	assert_eq(model.tick(0.5, Vector2.LEFT), 0)
	assert_eq(model.tick(0.21, Vector2.LEFT), 0)
