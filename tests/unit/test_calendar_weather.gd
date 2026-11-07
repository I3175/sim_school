extends GutTest

func test_time_conversion_and_forced_sleep_once() -> void:
	var clock := CalendarModel.new()
	clock.advance(100.0)
	assert_eq(clock.total_minutes, 370.0)
	var result := clock.advance(20000.0)
	assert_eq(clock.total_minutes, 1560.0)
	assert_true(result.forced)
	assert_false(clock.advance(100).forced)
	clock.sleep()
	assert_eq(clock.total_minutes, 1800.0)
	assert_eq(clock.day_index(), 1)

func test_calendar_boundaries_and_nested_pause() -> void:
	var clock := CalendarModel.new()
	clock.set_paused("menu", true)
	clock.set_paused("dialogue", true)
	clock.set_paused("menu", false)
	clock.advance(100.0)
	assert_eq(clock.total_minutes, 360.0)
	clock.set_paused("dialogue", false)
	clock.advance(100.0)
	assert_eq(clock.total_minutes, 370.0)
	for day in range(7):
		clock.sleep()
	assert_eq(clock.season_index(), 1)
	assert_eq(clock.day_of_season(), 1)
	for day in range(21):
		clock.sleep()
	assert_eq(clock.year(), 2)
	assert_eq(clock.season_index(), 0)

func test_weather_determinism_and_constraints_over_four_years() -> void:
	var first := WeatherModel.new()
	var second := WeatherModel.new()
	first.world_seed = 42
	second.world_seed = 42
	for day in range(112):
		var weather := first.day(day)
		assert_eq(weather, second.day(day))
		assert_lte(weather.weather_segments.size(), 3)
		if day < 3 or (day + 1) % 7 == 0:
			assert_eq(weather.weather, "sunny")
		if day > 0 and weather.weather in first.rules.heavy:
			assert_ne(weather.weather, first.day(day - 1).weather)
		assert_eq(first.forecast(day), second.forecast(day))
		assert_eq(first.at_minute(day, 120), first.at_minute(day, 1560))

func test_clock_json_roundtrip() -> void:
	var clock := CalendarModel.new()
	clock.advance(123.45)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(clock.snapshot()))
	var restored := CalendarModel.new()
	restored.restore(saved)
	assert_almost_eq(restored.total_minutes, clock.total_minutes, 0.00001)
