class_name WeatherModel
extends RefCounted
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weather/rules.json"))
var calendar: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/calendar.json"))
var world_seed: int = 20261107
var cache: Array[Dictionary] = []

func day(index: int) -> Dictionary:
	index = maxi(0, index)
	while cache.size() <= index:
		cache.append(_generate(cache.size()))
	return cache[index].duplicate(true)

func _rng(index: int, salt: int) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = world_seed * 1000003 + index * 9176 + salt
	return random

func _generate(index: int) -> Dictionary:
	var season: int = (index / int(calendar.days_per_season)) % int(calendar.seasons_per_year)
	var random := _rng(index, 17)
	var roll := random.randf() * 100.0
	var selected: String = "sunny"
	for position in range(rules.ids.size()):
		roll -= float(rules.weights[season][position])
		if roll < 0.0:
			selected = str(rules.ids[position])
			break
	var festival: bool = (index + 1) % int(calendar.days_per_season) == 0
	if index < 3 or festival:
		selected = "sunny"
	elif index > 0 and selected in rules.heavy and selected == str(cache[index - 1].weather):
		selected = "cloudy"
	var segments: Array = [{"minute": 360, "weather": selected}]
	if selected == "cloudy" and random.randf() < 0.35 and index >= 3 and not festival:
		segments.append({"minute": 840, "weather": "snow" if season == 3 else "rain"})
		segments.append({"minute": 1080, "weather": "cloudy"})
	var flags: Array[String] = []
	if festival:
		flags.append("festival")
	if index % int(calendar.days_per_season) == 3:
		flags.append("full_moon")
	if season != 1 and not festival and random.randf() < float(rules.forgetting_fog_chance):
		flags.append("fog_of_forgetting")
	if season == 2 and random.randf() < float(rules.wind_chance):
		flags.append("wind")
	if selected == "sunny" and random.randf() < float(rules.meteor_chance):
		flags.append("meteor_shower")
	if index > 0 and str(cache[index - 1].weather) in ["rain", "drizzle", "storm"] and selected == "sunny" and random.randf() < float(rules.rainbow_chance):
		flags.append("rainbow")
	return {"weather": selected, "weather_segments": segments, "special_flags": flags, "season": season, "temperature": calendar.temperature[season]}

func forecast(index: int) -> String:
	var actual: String = str(day(index).weather)
	if index < 3 or (index + 1) % int(calendar.days_per_season) == 0:
		return actual
	if _rng(index, 911).randf() < float(rules.forecast_accuracy):
		return actual
	return str(rules.neighbors.get(actual, actual))

func at_minute(index: int, minute: int) -> String:
	var record := day(index)
	var weather: String = str(record.weather)
	# After midnight still belongs to the previous agricultural day.
	if minute < int(calendar.day_start):
		minute += int(calendar.minutes_per_day)
	for segment: Dictionary in record.weather_segments:
		if minute >= int(segment.minute):
			weather = str(segment.weather)
	return weather
