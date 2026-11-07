class_name KnowledgeModel
extends RefCounted
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/knowledge.json"))
var banks: Dictionary = {}
var difficulty: Dictionary = {}
var high_streak: Dictionary = {}
var low_streak: Dictionary = {}
var leitner: Dictionary = {}
var xp: Dictionary = {}
var daily_reward: Dictionary = {}
var pinned_difficulty: int = 0

func _init() -> void:
	for subject: String in rules.subjects:
		banks[subject] = JSON.parse_string(FileAccess.get_file_as_string("res://data/questions/%s.json" % subject))
		difficulty[subject] = 1

func select_session(subject: String, seed_value: int) -> Array[Dictionary]:
	var tier: int = pinned_difficulty if pinned_difficulty > 0 else int(difficulty.get(subject, 1))
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var ranked: Array[Dictionary] = []
	for question: Dictionary in banks.get(subject, []):
		var box: int = int(leitner.get(question.id, {}).get("box", 1))
		var score: float = absf(float(question.difficulty) - tier) * 10.0 + random.randf() * box
		ranked.append({"question": question, "score": score})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) < float(b.score))
	var result: Array[Dictionary] = []
	for index in range(mini(int(rules.session_size), ranked.size())):
		result.append(ranked[index].question.duplicate(true))
	return result

func correct(question: Dictionary, response: Variant) -> bool:
	if question.type == "numeric_input":
		return str(response).is_valid_float() and is_equal_approx(float(response), float(question.answer))
	if question.type in ["multiple_choice", "fill_blank"]:
		return str(response).strip_edges().to_lower() == str(question.answer).strip_edges().to_lower()
	if question.type == "matching":
		return response is Dictionary and response == question.answer
	if not response is Array:
		return false
	var actual: Array = response.duplicate()
	var expected: Array = question.answer.duplicate()
	if question.type == "grid_puzzle":
		actual.sort()
		expected.sort()
	return actual == expected

func record_answer(id: String, success: bool) -> void:
	var record: Dictionary = leitner.get(id, {"streak": 0, "box": 1})
	record.streak = int(record.streak) + 1 if success else 0
	record.box = 3 if int(record.streak) >= 3 else (2 if int(record.streak) == 2 else 1)
	leitner[id] = record

func finish(subject: String, count: int, total: int, tier: int, day: int, practice: bool = false) -> Dictionary:
	var ratio: float = float(count) / maxf(1, total)
	var stars := 0
	if ratio >= 1.0 or (tier >= 4 and count >= total - 1):
		stars = 3
	elif ratio >= 0.8:
		stars = 2
	elif ratio >= 0.6:
		stars = 1
	if not practice:
		high_streak[subject] = int(high_streak.get(subject, 0)) + 1 if ratio >= 0.8 else 0
		low_streak[subject] = int(low_streak.get(subject, 0)) + 1 if ratio < 0.4 else 0
		if int(high_streak[subject]) >= 2:
			difficulty[subject] = mini(5, int(difficulty.get(subject, 1)) + 1)
			high_streak[subject] = 0
		if int(low_streak[subject]) >= 2:
			difficulty[subject] = maxi(1, int(difficulty.get(subject, 1)) - 1)
			low_streak[subject] = 0
		xp[subject] = int(xp.get(subject, 0)) + count * int(rules.knowledge_xp_per_correct)
	var first_today: bool = not practice and stars > 0 and int(daily_reward.get(subject, -1)) != day
	return {"stars": stars, "resident_xp": stars * int(rules.resident_xp_per_star) if not practice else 0, "daily_reward": first_today}

func snapshot() -> Dictionary:
	return {"difficulty": difficulty.duplicate(), "high_streak": high_streak.duplicate(), "low_streak": low_streak.duplicate(), "leitner": leitner.duplicate(true), "xp": xp.duplicate(), "daily_reward": daily_reward.duplicate(), "pinned_difficulty": pinned_difficulty}

func restore(saved: Dictionary) -> void:
	for subject: String in rules.subjects:
		difficulty[subject] = clampi(int(saved.get("difficulty", {}).get(subject, 1)), 1, 5)
	high_streak = saved.get("high_streak", {}).duplicate()
	low_streak = saved.get("low_streak", {}).duplicate()
	leitner = saved.get("leitner", {}).duplicate(true)
	xp = saved.get("xp", {}).duplicate()
	daily_reward = saved.get("daily_reward", {}).duplicate()
	pinned_difficulty = clampi(int(saved.get("pinned_difficulty", 0)), 0, 5)
