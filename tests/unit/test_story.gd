extends GutTest

func _finish_opening(model: StoryModel) -> void:
	model.record("reach", "farm_main")
	model.record("till")
	model.record("plant")
	model.record("talk", "di_nam")
	model.record("sleep")
	assert_true(model.finish_chapter(1))

func test_chapters_require_previous_completion_and_minimum_absolute_day() -> void:
	var model := StoryModel.new()
	assert_eq(model.chapter(28), 0, "No automatic year reset or chapter skip")
	assert_false(model.finish_chapter(28))
	_finish_opening(model)
	for id: String in StoryModel.NPCS: model.record("talk", id)
	model.record("harvest")
	model.record("reach", "school")
	assert_false(model.finish_chapter(0))
	assert_true(model.finish_chapter(1))
	assert_eq(model.chapter(2), -1)
	assert_eq(model.chapter(3), 2)
	assert_false(model.win_boss("eraser", 40, 700))
	assert_true(model.win_boss("zero", 31, 700))
	assert_false(model.win_boss("zero", 31, 700))
	assert_true(model.finish_chapter(31))
	var saved := JSON.parse_string(JSON.stringify(model.snapshot())) as Dictionary
	assert_true(StoryModel.valid_snapshot(saved))
	var restored := StoryModel.new()
	restored.restore(saved)
	assert_eq(restored.completed, 2)
	assert_eq(restored.chapter(31), 3)

func test_final_returns_each_winter_and_ending_follows_development() -> void:
	var model := StoryModel.new()
	model.completed = 1
	for index in range(5):
		assert_true(model.win_boss(StoryModel.BOSSES[index], 27, 1200))
		assert_true(model.finish_chapter(27))
	assert_false(model.can_challenge("final", 27, 1199))
	assert_false(model.can_challenge("final", 28, 1200))
	assert_false(model.can_challenge("final", 55, 1380))
	assert_true(model.can_challenge("final", 55, 1200))
	model.development.library = 12
	assert_true(model.win_boss("final", 55, 1200))
	assert_true(model.finish_chapter(55))
	assert_eq(model.ending, "library")
	assert_true(StoryModel.valid_snapshot(model.snapshot()))
	assert_false(model.finish_chapter(56))

func test_festival_boundaries_and_malformed_saves() -> void:
	var model := StoryModel.new()
	assert_eq(model.festival(6, 599), "")
	assert_eq(model.festival(6, 600), "Hội Hoa Xuân")
	assert_eq(model.festival(13, 1379), "Hội Biển Đêm")
	assert_eq(model.festival(20, 1380), "")
	assert_eq(model.festival(55, 1200), "Đêm Sao Rơi")
	var saved := model.snapshot()
	saved.completed = 7
	assert_false(StoryModel.valid_snapshot(saved), "Missing fragments must reject a finished story")
	saved.completed = -1
	saved.development.farm = -10
	assert_false(StoryModel.valid_snapshot(saved))
	assert_true(StoryModel.valid_snapshot({}))
