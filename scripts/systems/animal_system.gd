extends Node
var model := AnimalModel.new()
func _ready() -> void:
	model.world_seed = GameClock.world_seed
	model.last_day = GameClock.model.day_index()
	EventBus.day_started.connect(_day)
	EventBus.hour_changed.connect(func(_hour: int) -> void: model.advance_hours(1))
	EventBus.state_save_requested.connect(func(state: Dictionary) -> void: state.animals = model.snapshot())
	EventBus.state_load_requested.connect(func(state: Dictionary) -> void: model.restore(state.get("animals", {})))
	EventBus.map_entered.connect(_map_entered)

func _day(day: int) -> void:
	model.advance_day(day, GameClock.model.season_index(), WeatherSystem.current_weather)

func build(id: String) -> bool:
	if model.buildings.get(id, false):
		return false
	var cost: Dictionary = model.rules.buildings[id]
	var response := {}
	EventBus.inventory_transaction_requested.emit({"coins": -int(cost.coins), "remove": [{"id": "wood", "amount": int(cost.wood)}, {"id": "stone", "amount": int(cost.stone)}]}, response)
	if response.get("success", false):
		model.buildings[id] = true
		return true
	return false

func buy(kind: String) -> bool:
	if not model.can_add(kind):
		return false
	var response := {}
	EventBus.inventory_transaction_requested.emit({"coins": -(model.definitions[kind] as AnimalData).price}, response)
	return model.add(kind) if response.get("success", false) else false

func feed(amount: int) -> bool:
	if amount <= 0 or model.hay + amount > 240:
		return false
	var response := {}
	EventBus.inventory_transaction_requested.emit({"remove": [{"id": "hay", "amount": amount}]}, response)
	if response.get("success", false):
		model.hay += amount
		return true
	return false

func collect(index: int) -> bool:
	var products: Array = model.animals[index].products
	if products.is_empty():
		return false
	var response := {}
	EventBus.inventory_transaction_requested.emit({"add": products.duplicate(true)}, response)
	if response.get("success", false):
		products.clear()
		return true
	return false

func _map_entered(id: String) -> void:
	if id not in ["coop", "barn", "ranch"]:
		return
	var map: Node = SceneManager.cache[id]
	if map.has_node("AnimalStation"):
		return
	var station := Interactable.new()
	station.name = "AnimalStation"
	station.prompt = "Vật nuôi"
	station.position = Vector2(float(SceneManager.definitions[id].spawn[0]) + 32, float(SceneManager.definitions[id].spawn[1]) - 24)
	station.action = func() -> void: EventBus.animal_panel_requested.emit()
	map.add_child(station)
