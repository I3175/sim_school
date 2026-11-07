class_name ZeroEncounterModel
extends RefCounted

var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/zero_encounter.json"))
var phase: String = "dodge"
var round_index: int = 0
var elapsed: float = 0.0
var fall_timer: float = 0.0
var hazards: Array[Dictionary] = []
var mistakes: int = 0
var invulnerability: float = 0.0
var position := Vector2(152, 132)
const ARENA := Rect2(16, 54, 272, 96)
const TARGETS: Array[Vector2] = [Vector2(64, 74), Vector2(152, 74), Vector2(240, 74)]

func tick(delta: float, direction: Vector2) -> int:
	if phase in ["won", "closed"]:
		return 0
	position += direction.limit_length() * float(rules.player_speed) * delta
	position = position.clamp(ARENA.position + Vector2(5, 5), ARENA.end - Vector2(5, 5))
	invulnerability = maxf(0, invulnerability - delta)
	elapsed += delta
	fall_timer += delta
	if fall_timer >= float(rules.fall_interval):
		fall_timer = 0
		hazards.append({"center": position, "age": 0.0, "hit": false})
	var damage := 0
	for hazard: Dictionary in hazards:
		hazard.age = float(hazard.age) + delta
		if hazard.age >= float(rules.warning_seconds) and not hazard.hit:
			if invulnerability <= 0 and position.distance_to(hazard.center) <= 13:
				damage += int(rules.damage)
				invulnerability = 0.6
				hazard.hit = true
	hazards = hazards.filter(func(hazard: Dictionary) -> bool: return float(hazard.age) < float(rules.warning_seconds) + float(rules.impact_seconds))
	if phase == "dodge" and elapsed >= float(rules.dodge_seconds):
		phase = "answer"
	return damage

func attack() -> Dictionary:
	if phase != "answer":
		return {"result": "unavailable"}
	for index in range(TARGETS.size()):
		if position.distance_to(TARGETS[index]) > float(rules.attack_radius):
			continue
		if index != int(rules.rounds[round_index].correct):
			mistakes += 1
			return {"result": "wrong", "damage": int(rules.damage)}
		round_index += 1
		mistakes = 0
		elapsed = 0
		fall_timer = 0
		hazards.clear()
		phase = "won" if round_index == rules.rounds.size() else "dodge"
		return {"result": "won" if phase == "won" else "cracked"}
	return {"result": "out_of_range"}

func hint() -> String:
	if phase != "answer" or mistakes < 3:
		return ""
	var equation: Dictionary = rules.rounds[round_index]
	return "Gợi ý: kết quả là %d. Đến gần số đó và nhấn J." % int(equation.answers[int(equation.correct)])
