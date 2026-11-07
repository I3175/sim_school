extends GutTest
func test_chicken_cow_seven_days_and_quality_bands() -> void:
	var farm := AnimalModel.new()
	farm.buildings = {"coop": true, "barn": true}
	assert_true(farm.add("chicken"))
	assert_true(farm.add("cow"))
	farm.hay = 100
	farm.water = 100
	for day in range(1, 8):
		farm.pet(0, day)
		assert_false(farm.pet(0, day))
		farm.advance_hours(24)
		farm.advance_day(day, 0, "sunny")
	assert_eq(farm.animals[0].products.size(), 5)
	assert_eq(farm.animals[1].products.size(), 3)
	assert_eq(farm.animals[0].happiness, 70)
	assert_eq(farm.hay, 79)
	for seed_value in range(100):
		assert_eq(farm.quality(299, seed_value), 0)
		assert_lt(farm.quality(599, seed_value), 2)

func test_building_capacity_sickness_and_save() -> void:
	var farm := AnimalModel.new()
	assert_false(farm.add("chicken"))
	farm.buildings.coop = true
	for index in range(4):
		assert_true(farm.add("chicken"))
	assert_false(farm.add("chicken"))
	farm.advance_day(1, 3, "snow")
	assert_true(farm.animals[0].sick)
	assert_eq(farm.animals[0].health, 90)
	var restored := AnimalModel.new()
	restored.restore(JSON.parse_string(JSON.stringify(farm.snapshot())))
	assert_eq(restored.animals.size(), 4)
	assert_true(restored.animals[0].sick)
