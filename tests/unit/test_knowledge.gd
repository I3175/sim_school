extends GutTest
func test_banks_select_five_unique_questions_and_answers() -> void:
	var model := KnowledgeModel.new()
	for subject: String in model.rules.subjects:
		assert_gte(model.banks[subject].size(), 50)
		var selected := model.select_session(subject, 42)
		assert_eq(selected.size(), 5)
		var seen := {}
		for question: Dictionary in selected:
			assert_false(seen.has(question.id))
			seen[question.id] = true
			assert_true(model.correct(question, question.answer))
		for question: Dictionary in model.banks[subject]:
			assert_true(model.correct(question, question.answer), question.id)

func test_adaptation_stars_and_leitner() -> void:
	var model := KnowledgeModel.new()
	assert_eq(model.finish("math", 3, 5, 1, 0).stars, 1)
	model.finish("math", 4, 5, 1, 0)
	model.finish("math", 4, 5, 1, 0)
	assert_eq(model.difficulty.math, 2)
	model.finish("math", 1, 5, 2, 0)
	model.finish("math", 1, 5, 2, 0)
	assert_eq(model.difficulty.math, 1)
	assert_eq(model.finish("math", 4, 5, 4, 0).stars, 3)
	for index in range(3): model.record_answer("math_0001", true)
	assert_eq(model.leitner.math_0001.box, 3)
	model.record_answer("math_0001", false)
	assert_eq(model.leitner.math_0001.box, 1)

func test_practice_does_not_award_xp_and_story_help_after_three_failures() -> void:
	var model := KnowledgeModel.new()
	var result := model.finish("math", 5, 5, 1, 0, true)
	assert_eq(result.resident_xp, 0)
	assert_false(result.daily_reward)
	assert_true(model.xp.is_empty())
	var id := "unit_test_puzzle"
	KnowledgeManager.puzzle_failures.erase(id)
	assert_eq(KnowledgeManager.story_puzzle_result(id, 0), 0)
	assert_eq(KnowledgeManager.story_puzzle_result(id, 0), 0)
	assert_eq(KnowledgeManager.story_puzzle_result(id, 0), 1)
	KnowledgeManager.puzzle_failures.erase(id)
