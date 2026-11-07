class_name FishingModel
extends RefCounted
var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/fishing/fish.json"))
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/fishing.json"))
var state: String = "idle"
var fish: Dictionary = {}
var random := RandomNumberGenerator.new()
var timer: float = 0.0
var bar: float = 0.5
var fish_position: float = 0.5
var progress: float = 0.3
var perfect: bool = true
var cast_power: float = 0.0
var fish_velocity: float = 0.0
var target_timer: float = 0.0

func eligible(zone: String, season: int, minute: int, weather: String, flags: Array) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for entry: Dictionary in catalog:
		if zone not in entry.zones or not entry.seasons.any(func(value: Variant) -> bool: return int(value) == season):
			continue
		var start := int(entry.start)
		var end := int(entry.end)
		if start != end:
			var inside: bool = minute >= start and minute < end if start < end else minute >= start or minute < end
			if not inside:
				continue
		if not entry.weather.is_empty() and weather not in entry.weather:
			continue
		if entry.flag != "" and entry.flag not in flags:
			continue
		available.append(entry)
	return available

func begin(available: Array[Dictionary], seed_value: int) -> bool:
	if state != "idle" or available.is_empty():
		return false
	random.seed = seed_value
	fish = available[random.randi_range(0, available.size() - 1)].duplicate(true)
	state = "casting"
	cast_power = 0.0
	perfect = true
	return true

func release_cast() -> void:
	if state == "casting":
		state = "waiting"
		timer = random.randf_range(float(rules.wait_min), float(rules.wait_max))

func hook() -> void:
	if state == "bite":
		state = "reeling"
		bar = 0.5
		fish_position = 0.5
		progress = float(rules.initial_progress)
		target_timer = 0.0

func tick(delta: float, held: bool) -> void:
	if state == "casting":
		cast_power = fposmod(cast_power + delta * 0.5, 1.0)
	elif state in ["waiting", "bite"]:
		timer -= delta
		if timer <= 0.0:
			if state == "waiting":
				state = "bite"
				timer = float(rules.bite_window)
			else:
				state = "escaped"
	elif state == "reeling":
		bar = clampf(bar + (1.0 if held else -1.0) * float(rules.bar_speed) * delta, 0.0, 1.0)
		target_timer -= delta
		if target_timer <= 0:
			target_timer = random.randf_range(0.3, 0.9)
			fish_velocity = random.randf_range(-1.0, 1.0) * (0.08 + float(fish.difficulty) * 0.06)
		fish_position = clampf(fish_position + fish_velocity * delta, 0.0, 1.0)
		var inside: bool = absf(bar - fish_position) <= float(rules.bar_width) / 2.0
		if not inside:
			perfect = false
		progress = clampf(progress + (float(rules.progress_gain) if inside else -float(rules.progress_loss)) * delta, 0.0, 1.0)
		if progress >= 1.0:
			state = "caught"
		elif progress <= 0.0:
			state = "escaped"

func reward() -> Dictionary:
	if state != "caught":
		return {}
	return {"id": "fish_" + str(fish.id), "amount": 1, "quality": int(rules.quality_perfect) if perfect else 0, "xp": roundi(int(fish.xp) * (float(rules.perfect_xp_multiplier) if perfect else 1.0))}

static func low_tide(total_minutes: float) -> bool:
	return fposmod(total_minutes, 360.0) >= 180.0
