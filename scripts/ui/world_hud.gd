extends CanvasLayer
var label: Label
var paused: bool = false

func _ready() -> void:
	label = Label.new()
	label.position = Vector2(5, 4)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_shadow_color", Color("243d35"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

func _process(_delta: float) -> void:
	label.visible = GameClock.model.pauses.is_empty()
	var clock: CalendarModel = GameClock.model
	var minute: int = (clock.minute_of_day() / 10) * 10
	var weather_index: int = WeatherSystem.model.rules.ids.find(WeatherSystem.current_weather)
	var weather_name: String = str(WeatherSystem.model.rules.names[weather_index])
	var forecast_index: int = WeatherSystem.model.rules.ids.find(WeatherSystem.state.get("forecast", "sunny"))
	label.text = "Ngày %d · %s %d · %02d:%02d · %s\nMai: %s · F8 tua +1h · F9 ngủ · P tạm dừng" % [clock.day_of_season(), clock.rules.season_names[clock.season_index()], clock.year(), minute / 60, minute % 60, weather_name, WeatherSystem.model.rules.names[forecast_index]]
	if clock.awaiting_sleep:
		label.text += "\nĐã 02:00 — đang được đưa về nhà…"

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F8 and OS.is_debug_build():
		GameClock.advance(600.0)
	elif event.keycode == KEY_F9 and OS.is_debug_build():
		EventBus.sleep_requested.emit()
	elif event.keycode == KEY_P:
		if not GameClock.model.pauses.is_empty() and not GameClock.model.pauses.has("pause_menu"):
			return
		paused = not paused
		EventBus.pause_requested.emit("pause_menu", paused)
		get_tree().paused = paused

