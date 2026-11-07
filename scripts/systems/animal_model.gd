class_name AnimalModel
extends RefCounted
var definitions: Dictionary = {"chicken": preload("res://data/animals/chicken.tres"), "cow": preload("res://data/animals/cow.tres")}
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/animals.json"))
var animals: Array[Dictionary] = []
var buildings: Dictionary = {"coop": false, "barn": false}
var hay: int = 0
var water: int = 0
var door_open: bool = false
var heater: bool = false
var last_day: int = 0
var next_id: int = 1
var world_seed: int = 20261107

func can_add(kind: String) -> bool:
	if not definitions.has(kind):
		return false
	var data: AnimalData = definitions[kind]
	if not buildings.get(data.building, false):
		return false
	var count := 0
	for animal: Dictionary in animals:
		if (definitions[animal.kind] as AnimalData).building == data.building:
			count += 1
	return count < int(rules.buildings[data.building].capacity)

func add(kind: String) -> bool:
	if not can_add(kind):
		return false
	animals.append({"id": "animal_%d" % next_id, "kind": kind, "age": 0, "hunger": 100.0, "thirst": 100.0, "happiness": 0, "health": 100, "sick": false, "pet_day": -1, "products": [], "starved_days": 0})
	next_id += 1
	return true

func pet(index: int, day: int) -> bool:
	if index < 0 or index >= animals.size() or int(animals[index].pet_day) == day:
		return false
	animals[index].pet_day = day
	animals[index].happiness = mini(1000, int(animals[index].happiness) + int(rules.pet_happiness))
	return true

func advance_hours(hours: float) -> void:
	for animal: Dictionary in animals:
		animal.hunger = maxf(0, float(animal.hunger) - float(rules.hunger_per_hour) * hours)
		animal.thirst = maxf(0, float(animal.thirst) - float(rules.thirst_per_hour) * hours)

func advance_day(day: int, season: int, weather: String) -> void:
	if day <= last_day:
		return
	for animal: Dictionary in animals:
		var data: AnimalData = definitions[animal.kind]
		animal.age = int(animal.age) + 1
		var grazing: bool = door_open and season != 3 and weather in ["sunny", "cloudy"]
		var fed: bool = grazing or hay >= data.food_per_day
		var watered: bool = water > 0
		if fed:
			if not grazing:
				hay -= data.food_per_day
			animal.hunger = 100.0
			animal.starved_days = 0
		else:
			animal.starved_days = int(animal.starved_days) + 1
			animal.happiness = maxi(0, int(animal.happiness) - int(rules.hungry_penalty))
		if watered:
			water -= 1
			animal.thirst = 100.0
		if grazing:
			animal.happiness = mini(1000, int(animal.happiness) + int(rules.grass_happiness))
		if door_open:
			animal.happiness = maxi(0, int(animal.happiness) - int(rules.night_outside_penalty))
		if (not fed and int(animal.starved_days) >= 1) or not watered or (season == 3 and not heater):
			animal.sick = true
		if animal.sick:
			animal.health = maxi(0, int(animal.health) - int(rules.sick_health_loss))
		elif int(animal.age) >= data.maturity_days and int(animal.age) % data.product_interval == 0:
			animal.products.append({"id": data.product_id, "amount": 1, "quality": quality(int(animal.happiness), hash("%d:%s:%d" % [world_seed, animal.id, day]))})
	last_day = day

func quality(happiness: int, seed_value: int) -> int:
	var weights: Array = rules.quality_bands[0].weights
	for band: Dictionary in rules.quality_bands:
		if happiness >= int(band.minimum):
			weights = band.weights
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var roll := random.randf() * 100.0
	for index in range(4):
		roll -= float(weights[index])
		if roll < 0:
			return index
	return 0

func snapshot() -> Dictionary:
	return {"animals": animals.duplicate(true), "buildings": buildings.duplicate(), "hay": hay, "water": water, "door_open": door_open, "heater": heater, "last_day": last_day, "next_id": next_id}

func restore(saved: Dictionary) -> void:
	animals.assign(saved.get("animals", []).duplicate(true))
	buildings = saved.get("buildings", {"coop": false, "barn": false}).duplicate()
	hay = int(saved.get("hay", 0))
	water = int(saved.get("water", 0))
	door_open = bool(saved.get("door_open", false))
	heater = bool(saved.get("heater", false))
	last_day = int(saved.get("last_day", 0))
	next_id = int(saved.get("next_id", 1))
