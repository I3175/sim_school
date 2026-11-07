extends GutTest
func test_every_fish_can_appear_only_with_required_conditions() -> void:
	var model := FishingModel.new()
	assert_eq(model.catalog.size(), 14)
	for fish: Dictionary in model.catalog:
		var minute: int = int(fish.start) if int(fish.start) != int(fish.end) else 600
		var weather: String = str(fish.weather[0]) if not fish.weather.is_empty() else "sunny"
		var flags: Array = [fish.flag] if fish.flag != "" else []
		var found := model.eligible(str(fish.zones[0]), int(fish.seasons[0]), minute, weather, flags)
		assert_true(found.any(func(entry: Dictionary) -> bool: return entry.id == fish.id), fish.id)
		assert_true(model.eligible("invalid_zone", int(fish.seasons[0]), minute, weather, flags).is_empty())
	assert_true(model.eligible("sea", 3, 0, "sunny", []).all(func(entry: Dictionary) -> bool: return entry.id != "moon_fish"))

func test_bite_timeout_catch_and_perfect_reward() -> void:
	var model := FishingModel.new()
	var options := model.eligible("lake", 0, 600, "sunny", [])
	assert_true(model.begin(options, 42))
	model.release_cast()
	model.tick(3.1, false)
	assert_eq(model.state, "bite")
	model.tick(1.1, false)
	assert_eq(model.state, "escaped")
	model.state = "idle"
	model.begin(options, 42)
	model.release_cast()
	model.tick(3.1, false)
	model.hook()
	for step in range(2000):
		model.tick(0.01, model.bar < model.fish_position)
		if model.state != "reeling":
			break
	assert_eq(model.state, "caught")
	assert_true(model.perfect)
	assert_eq(model.reward().quality, 1)
	assert_eq(model.reward().xp, 12)
	assert_false(FishingModel.low_tide(0))
	assert_true(FishingModel.low_tide(180))
	assert_false(FishingModel.low_tide(360))
