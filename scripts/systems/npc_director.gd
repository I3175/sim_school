extends Node
const NPC_SCRIPT = preload("res://scripts/entities/village_npc.gd")
var model := SocialModel.new()
var actors: Dictionary = {}

func _ready() -> void:
	EventBus.map_entered.connect(func(_id: String) -> void: _sync())
	EventBus.minute_changed.connect(func(_minute: int) -> void: _sync())
	EventBus.weather_changed.connect(func(_weather: String) -> void: _sync())
	EventBus.npc_talk_requested.connect(_talk)
	EventBus.npc_gift_requested.connect(_gift)
	EventBus.state_save_requested.connect(func(state: Dictionary) -> void: state.npcs = model.snapshot())
	EventBus.state_load_requested.connect(func(state: Dictionary) -> void: model.restore(state.get("npcs", {})))
	EventBus.state_restored.connect(_sync)
	_sync()

func _sync() -> void:
	if not SceneManager.cache.has(SceneManager.current_map_id):
		return
	for id: String in model.catalog:
		var activity := model.activity(id, GameClock.model.day_index(), GameClock.model.minute_of_day(), WeatherSystem.current_weather)
		if activity.map_id != SceneManager.current_map_id:
			if actors.has(id):
				actors[id].queue_free()
				actors.erase(id)
			continue
		var target := Vector2(float(activity.position_marker[0]), float(activity.position_marker[1]))
		if not actors.has(id):
			var actor := CharacterBody2D.new()
			actor.set_script(NPC_SCRIPT)
			actor.npc_id = id
			actor.position = target
			actor.destination = target
			actor.speed = float(model.rules.npc_speed)
			SceneManager.cache[SceneManager.current_map_id].get_node("Entities").add_child(actor)
			actors[id] = actor
		actors[id].destination = target

func _talk(id: String) -> void:
	model.talk(id, GameClock.model.day_index())
	EventBus.friendship_changed.emit(model.friendships.duplicate())
	var cue := "start"
	if WeatherSystem.current_weather in ["drizzle", "rain", "storm", "blizzard"]:
		cue = "rain"
	elif int(model.friendships.get(id, 0)) >= 200:
		cue = "friendly"
	EventBus.dialogue_requested.emit(id, cue)
	EventBus.npc_talked.emit(id)

func _gift(id: String) -> void:
	var slot: Dictionary = InventoryManager.bag.slots[InventoryManager.selected_slot]
	if slot.is_empty() or int(model.gifted_on.get(id, -1)) == GameClock.model.day_index():
		EventBus.notice_requested.emit("Mỗi người nhận một món quà mỗi ngày")
		return
	var item_id := str(slot.id)
	var response := {}
	EventBus.inventory_transaction_requested.emit({"remove": [{"id": item_id, "amount": 1, "quality": int(slot.quality)}]}, response)
	if response.get("success", false):
		model.gift(id, item_id, GameClock.model.day_index())
		EventBus.friendship_changed.emit(model.friendships.duplicate())
		EventBus.notice_requested.emit("Đã tặng quà")
