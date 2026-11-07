extends Node
var model := CalendarModel.new()
var world_seed: int = 20261107

func _ready() -> void:
	EventBus.pause_requested.connect(model.set_paused)
	EventBus.sleep_requested.connect(start_next_day)
	EventBus.state_save_requested.connect(func(state: Dictionary) -> void: state.clock = snapshot())
	EventBus.state_validate_requested.connect(_validate_saved_clock)
	EventBus.state_load_requested.connect(func(state: Dictionary) -> void: restore(state.clock))

func _process(delta: float) -> void:
	advance(delta)

func advance(real_seconds: float) -> void:
	var result: Dictionary = model.advance(real_seconds)
	for minute in range(int(result.before) + 1, int(result.after) + 1):
		EventBus.minute_changed.emit(minute)
		if minute % 60 == 0:
			EventBus.hour_changed.emit((minute / 60) % 24)
	if result.forced:
		EventBus.forced_sleep_triggered.emit()

func start_next_day() -> void:
	var previous_season := model.season_index()
	model.sleep()
	if previous_season != model.season_index():
		EventBus.season_changed.emit(model.season_index())
	EventBus.day_started.emit(model.day_index())
	EventBus.minute_changed.emit(int(model.total_minutes))
	EventBus.hour_changed.emit(model.minute_of_day() / 60)

func snapshot() -> Dictionary:
	var state := model.snapshot()
	state.world_seed = world_seed
	return state

func restore(state: Dictionary) -> void:
	var previous_pauses := model.pauses.duplicate()
	model.restore(state)
	model.pauses = previous_pauses
	world_seed = int(state.get("world_seed", world_seed))
	EventBus.season_changed.emit(model.season_index())

func _validate_saved_clock(state: Dictionary, errors: Array) -> void:
	var saved: Variant = state.get("clock")
	if not saved is Dictionary or not (saved.get("total_game_minutes") is float or saved.get("total_game_minutes") is int):
		errors.append("Đồng hồ không hợp lệ")
		return
	if float(saved.total_game_minutes) < 360.0 or not is_finite(float(saved.total_game_minutes)) or not (saved.get("world_seed") is float or saved.get("world_seed") is int):
		errors.append("Thời gian/seed không hợp lệ")
