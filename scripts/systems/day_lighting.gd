extends CanvasModulate
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/calendar.json"))

func _process(_delta: float) -> void:
	color = light_at(GameClock.model.total_minutes, GameClock.model.season_index())

func light_at(total_minutes: float, season: int) -> Color:
	var minute: float = fposmod(total_minutes, 1440.0)
	var sunrise: float = float(rules.sunrise[season])
	var sunset: float = float(rules.sunset[season])
	var stops: Array = [[0.0, Color("3a4478")], [sunrise - 60.0, Color("3a4478")], [sunrise, Color("ffc9a0")], [sunrise + 60.0, Color.WHITE], [660.0, Color("fffff0")], [900.0, Color("fff0c8")], [sunset - 60.0, Color("e8a0a0")], [sunset + 60.0, Color("8070b0")], [sunset + 90.0, Color("5060a0")], [1380.0, Color("3a4478")], [1440.0, Color("3a4478")]]
	for index in range(1, stops.size()):
		if minute <= float(stops[index][0]):
			var previous: Array = stops[index - 1]
			var current: Array = stops[index]
			var ratio: float = inverse_lerp(float(previous[0]), float(current[0]), minute)
			return (previous[1] as Color).lerp(current[1], ratio)
	return Color("3a4478")
