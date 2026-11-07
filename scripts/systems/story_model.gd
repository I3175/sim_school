class_name StoryModel
extends RefCounted

const OPEN_DAYS: Array[int] = [0, 1, 3, 7, 11, 14, 18, 21]
const TITLES: Array[String] = ["Lá Thư", "Hạt Giống Đầu Tiên", "Ngôi Trường Im Lặng", "Thư Viện Bị Khóa", "Tiếng Sóng Ngoại Ngữ", "Mỏ Đá Thì Thầm", "Núi Mây và Ký Ức", "Đêm Sao Rơi"]
const BOSSES: Array[String] = ["zero", "eraser", "sailor", "golem", "memory", "final"]
const SUBJECTS: Array[String] = ["math", "literature", "english", "science", "history_geo"]
const NPCS: Array[String] = ["di_nam", "chu_ba", "bac_si_minh", "chi_vy", "co_lan", "co_mai", "lao_quang", "thu_thu", "ong_sau", "be_na", "anh_khoa", "marco"]
var completed: int = -1
var facts: Dictionary = {}
var defeated: Dictionary = {}
var development: Dictionary = {"school": 0, "library": 0, "farm": 0}
var ending: String = ""

func chapter(day: int) -> int:
	var next := completed + 1
	return next if next < OPEN_DAYS.size() and day >= OPEN_DAYS[next] else -1

func record(kind: String, target: String = "") -> void:
	facts[kind + ":" + target] = true

func has_fact(kind: String, target: String = "") -> bool:
	return bool(facts.get(kind + ":" + target, false))

func requirements(index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match index:
		0:
			result = [_need("Đến nông trại", has_fact("reach", "farm_main")), _need("Cuốc đất", has_fact("till")), _need("Trồng hạt đầu", has_fact("plant")), _need("Gặp Dì Năm", has_fact("talk", "di_nam")), _need("Ngủ đêm đầu", has_fact("sleep"))]
		1:
			for id: String in NPCS:
				result.append(_need("Gặp " + id, has_fact("talk", id)))
			result.append(_need("Thu hoạch lần đầu", has_fact("harvest")))
			result.append(_need("Đến lớp học", has_fact("reach", "school")))
		2, 3, 4, 5, 6:
			result.append(_need("Vượt Bóng Quên", bool(defeated.get(BOSSES[index - 2], false))))
		7:
			for id: String in BOSSES.slice(0, 5):
				result.append(_need("Mảnh Sao · " + id, bool(defeated.get(id, false))))
			result.append(_need("Nhắc nhớ Kẻ Xóa Chữ", bool(defeated.get("final", false))))
	return result

func _need(caption: String, done: bool) -> Dictionary:
	return {"caption": caption, "done": done}

func finish_chapter(day: int) -> bool:
	var active := chapter(day)
	if active < 0:
		return false
	for condition: Dictionary in requirements(active):
		if not condition.done:
			return false
	completed = active
	if completed == 7:
		ending = "farm"
		# On a tie, the farm inherited in the opening remains the epilogue focus.
		for place: String in ["school", "library"]:
			if int(development[place]) > int(development[ending]):
				ending = place
	return true

func can_challenge(id: String, day: int, minute: int) -> bool:
	if id not in BOSSES or defeated.has(id):
		return false
	var active := chapter(day)
	if id == "final":
		return active == 7 and day % 28 == 27 and minute >= 1200 and minute < 1380
	return active == BOSSES.find(id) + 2

func win_boss(id: String, day: int, minute: int) -> bool:
	if not can_challenge(id, day, minute):
		return false
	defeated[id] = true
	return true

func festival(day: int, minute: int) -> String:
	if day % 7 != 6 or minute < 600 or minute >= 1380:
		return ""
	return ["Hội Hoa Xuân", "Hội Biển Đêm", "Hội Gặt", "Đêm Sao Rơi"][(day / 7) % 4]

func snapshot() -> Dictionary:
	return {"completed": completed, "facts": facts.duplicate(), "defeated": defeated.duplicate(), "development": development.duplicate(), "ending": ending}

static func valid_snapshot(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true # Saves predating the story system begin at the opening.
	var count: Variant = value.get("completed")
	if not (count is int or count is float) or not is_finite(float(count)) or float(count) != floor(float(count)) or count < -1 or count > 7:
		return false
	for field: String in ["facts", "defeated", "development"]:
		if not value.get(field) is Dictionary:
			return false
	for id: String in value.defeated:
		if id not in BOSSES or value.defeated[id] != true:
			return false
	for flag: Variant in value.facts.values():
		if not flag is bool:
			return false
	for place: String in ["school", "library", "farm"]:
		var score: Variant = value.development.get(place)
		if not (score is float or score is int) or not is_finite(float(score)) or score < 0:
			return false
	for index in range(2, int(count) + 1):
		if not value.defeated.get(BOSSES[index - 2], false):
			return false
	return value.get("ending", "") in ["", "school", "library", "farm"]

func restore(value: Dictionary) -> void:
	completed = int(value.get("completed", -1))
	facts = value.get("facts", {}).duplicate()
	defeated = value.get("defeated", {}).duplicate()
	development = value.get("development", {"school": 0, "library": 0, "farm": 0}).duplicate()
	ending = str(value.get("ending", ""))
