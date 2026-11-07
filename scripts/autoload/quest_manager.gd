extends Node
var model := QuestModel.new()
var discovered: Array[String] = []
var friendships: Dictionary = {}
func _ready() -> void:
	EventBus.state_validate_requested.connect(_validate_state)
	EventBus.crop_harvested.connect(func(id: String, _quality: int) -> void: _record("harvest", id))
	EventBus.npc_talked.connect(func(id: String) -> void: _record("talk", id))
	EventBus.map_entered.connect(_map_entered)
	EventBus.day_started.connect(func(_day: int) -> void: refresh())
	EventBus.flag_unlocked.connect(func(_flag: String) -> void: refresh.call_deferred())
	EventBus.friendship_changed.connect(func(values: Dictionary) -> void: friendships = values; refresh())
	EventBus.state_save_requested.connect(func(state: Dictionary) -> void: state.quests = model.snapshot(); state.quests.discovered = discovered.duplicate())
	EventBus.state_load_requested.connect(func(state: Dictionary) -> void: model.restore(state.get("quests", {})); discovered.assign(state.get("quests", {}).get("discovered", [])))
	EventBus.state_restored.connect(refresh)
	refresh.call_deferred()

func refresh() -> void:
	model.refresh({"day": GameClock.model.day_index(), "flags": SceneManager.flags, "friendships": friendships, "discovered": discovered})
	EventBus.quests_changed.emit()

func accept(id: String) -> void:
	if model.accept(id, GameClock.model.day_index()):
		EventBus.quests_changed.emit()

func claim(id: String) -> bool:
	if not model.states.has(id) or model.states[id].status != "Ready":
		return false
	var reward: Dictionary = model.definitions[id].rewards
	var response := {}
	EventBus.inventory_transaction_requested.emit({"coins": int(reward.get("coins", 0)), "add": reward.get("items", [])}, response)
	if not response.get("success", false):
		return false
	model.claim(id, GameClock.model.day_index())
	for flag: String in reward.get("flags", []):
		EventBus.flag_unlocked.emit(flag)
	EventBus.resident_xp_awarded.emit(int(reward.get("xp", 0)))
	EventBus.quests_changed.emit()
	return true

func _map_entered(id: String) -> void:
	if id not in discovered:
		discovered.append(id)
	refresh()
	_record("reach", id)

func _record(event: String, target: String) -> void:
	model.record(event, target)
	EventBus.quests_changed.emit()

func _validate_state(saved: Dictionary, errors: Array) -> void:
	var quests: Variant = saved.get("quests", {})
	if not quests is Dictionary or not quests.get("states", {}) is Dictionary or not quests.get("pinned", []) is Array:
		errors.append("Nhật ký không hợp lệ")
		return
	for id: String in quests.get("states", {}):
		var state: Variant = quests.states[id]
		if not model.definitions.has(id) or not state is Dictionary or not state.get("progress") is Array or state.get("status") not in ["Locked", "Available", "Active", "Ready", "Claimed", "Expired", "Failed"]:
			errors.append("Trạng thái nhiệm vụ không hợp lệ")
			continue
		if state.status in ["Active", "Ready", "Claimed"] and state.progress.size() != model.definitions[id].objectives.size():
			errors.append("Tiến độ nhiệm vụ không hợp lệ")
