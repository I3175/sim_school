extends Node
var model := WeatherModel.new()
var current_day: int = 0
var current_weather: String = "sunny"
var wetness: float = 0.0
var snow_cover: float = 0.0
var last_minute: int = 360
var state: Dictionary = {}

func _ready() -> void:
	EventBus.state_validate_requested.connect(_validate_state)
	EventBus.state_save_requested.connect(func(saved: Dictionary) -> void: saved.weather = snapshot())
	EventBus.state_load_requested.connect(func(saved: Dictionary) -> void: restore(saved.get("weather", {})))
	EventBus.state_restored.connect(func() -> void: _on_day_started(GameClock.model.day_index()))
	EventBus.day_started.connect(_on_day_started)
	EventBus.minute_changed.connect(_on_minute_changed)
	_on_day_started(0)

func _on_day_started(day_index: int) -> void:
	current_day = day_index
	if model.world_seed != GameClock.world_seed:
		model.world_seed = GameClock.world_seed
		model.cache.clear()
	state = model.day(day_index)
	state.forecast = model.forecast(day_index + 1)
	last_minute = day_index * 1440 + 360
	_apply_weather(model.at_minute(day_index, 360))

func _on_minute_changed(total_minutes: int) -> void:
	var minute: int = total_minutes % 1440
	_apply_weather(model.at_minute(current_day, minute))
	var elapsed_hours: float = maxf(0.0, float(total_minutes - last_minute) / 60.0)
	last_minute = total_minutes
	if current_weather in ["drizzle", "rain", "storm"]:
		wetness = clampf(wetness + float(model.rules.wetness_rain_per_hour) * elapsed_hours, 0.0, 1.0)
	elif current_weather == "sunny":
		wetness = clampf(wetness + float(model.rules.wetness_sun_per_hour) * elapsed_hours, 0.0, 1.0)
		snow_cover = clampf(snow_cover + float(model.rules.melt_per_hour) * elapsed_hours, 0.0, 1.0)
	if current_weather in ["snow", "blizzard"]:
		snow_cover = clampf(snow_cover + float(model.rules.snow_per_hour) * elapsed_hours, 0.0, 1.0)
	state.wetness = wetness
	state.snow_cover = snow_cover
	state.weather = current_weather
	EventBus.environment_changed.emit(state.duplicate(true))

func _apply_weather(weather: String) -> void:
	if current_weather != weather:
		current_weather = weather
		EventBus.weather_changed.emit(weather)
	state.weather = weather

func snapshot() -> Dictionary:
	return {"wetness": wetness, "snow_cover": snow_cover}

func restore(saved: Dictionary) -> void:
	wetness = clampf(float(saved.get("wetness", 0)), 0.0, 1.0)
	snow_cover = clampf(float(saved.get("snow_cover", 0)), 0.0, 1.0)
	_on_minute_changed(last_minute)

func _validate_state(saved: Dictionary, errors: Array) -> void:
	var weather: Variant = saved.get("weather", {})
	if not weather is Dictionary:
		errors.append("Thời tiết không hợp lệ")
		return
	for field: String in ["wetness", "snow_cover"]:
		var value: Variant = weather.get(field, 0)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0 or float(value) > 1:
			errors.append("Chỉ số thời tiết không hợp lệ")
