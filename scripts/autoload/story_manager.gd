extends Node
var model := StoryModel.new()

func _ready() -> void:
	EventBus.map_entered.connect(func(id: String) -> void: record("reach", id))
	EventBus.npc_talked.connect(func(id: String) -> void: record("talk", id))
	EventBus.farm_action_completed.connect(func(kind: String) -> void: record(kind))
	EventBus.crop_harvested.connect(func(_id: String, _quality: int) -> void:
		model.development.farm = int(model.development.farm) + 1
		record("harvest"))
	EventBus.day_started.connect(func(_day: int) -> void: record("sleep"))
	EventBus.knowledge_session_finished.connect(func(subject: String, stars: int) -> void:
		var place := "library" if subject in ["literature", "history_geo"] else "school"
		model.development[place] = int(model.development[place]) + stars)
	EventBus.resident_xp_awarded.connect(func(_amount: int) -> void: _unlock_maps.call_deferred())
	EventBus.state_save_requested.connect(func(state: Dictionary) -> void: state.story = model.snapshot())
	EventBus.state_load_requested.connect(func(state: Dictionary) -> void: model.restore(state.get("story", {})))
	EventBus.state_validate_requested.connect(func(state: Dictionary, errors: Array) -> void:
		if not StoryModel.valid_snapshot(state.get("story", {})): errors.append("Tiến độ cốt truyện không hợp lệ"))
	EventBus.state_restored.connect(_unlock_maps)

func record(kind: String, target: String = "") -> void:
	model.record(kind, target)
	refresh()

func refresh() -> void:
	if model.finish_chapter(GameClock.model.day_index()):
		EventBus.notice_requested.emit("Hoàn thành: " + StoryModel.TITLES[model.completed])
	_unlock_maps()
	EventBus.story_changed.emit()

func _unlock_maps() -> void:
	if model.completed >= 1:
		EventBus.flag_unlocked.emit("chapter_1")
	if is_instance_valid(SceneManager.player):
		if model.completed >= 1 and SceneManager.player.resident_level >= 3:
			EventBus.flag_unlocked.emit("mine_unlocked")
		if model.completed >= 5 and SceneManager.player.resident_level >= 8:
			EventBus.flag_unlocked.emit("mountain_unlocked")
	# The bridge requires its own repair objective; chapter completion alone
	# must not grant it. The chapter-four encounter will consume that objective.

func complete_boss(id: String) -> bool:
	if not model.win_boss(id, GameClock.model.day_index(), GameClock.model.minute_of_day()):
		return false
	refresh()
	return true
