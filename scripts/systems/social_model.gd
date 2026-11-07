class_name SocialModel
extends RefCounted
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/social.json"))
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs/catalog.json"))
var schedules: Dictionary = {}
var friendships: Dictionary = {}
var talked_on: Dictionary = {}
var gifted_on: Dictionary = {}
func _init() -> void:
	for id: String in catalog:
		schedules[id] = JSON.parse_string(FileAccess.get_file_as_string("res://data/schedules/%s.json" % id))

func activity(id: String, day: int, minute: int, weather: String) -> Dictionary:
	var kind := "weekend" if day % 7 >= 5 else "weekday"
	if weather in ["drizzle", "rain", "storm", "blizzard"]:
		kind = "rain"
	if day % 7 == 6:
		kind = "festival"
	var schedule: Array = schedules[id][kind]
	var result: Dictionary = schedule[0]
	if minute < 360:
		minute += 1440
	for entry: Dictionary in schedule:
		if int(entry.start_minute) <= minute:
			result = entry
	return result.duplicate(true)

func talk(id: String, day: int) -> bool:
	if not catalog.has(id) or int(talked_on.get(id, -1)) == day:
		return false
	talked_on[id] = day
	friendships[id] = mini(int(rules.max_friendship), int(friendships.get(id, 0)) + int(rules.talk_points))
	return true

func gift(id: String, item_id: String, day: int) -> bool:
	if not catalog.has(id) or int(gifted_on.get(id, -1)) == day:
		return false
	var preference := "neutral"
	for kind: String in ["loved", "liked", "hated"]:
		if item_id in catalog[id][kind]:
			preference = kind
	friendships[id] = clampi(int(friendships.get(id, 0)) + int(rules.gift_points[preference]), 0, int(rules.max_friendship))
	gifted_on[id] = day
	return true

func snapshot() -> Dictionary:
	return {"friendships": friendships.duplicate(), "talked_on": talked_on.duplicate(), "gifted_on": gifted_on.duplicate()}

func restore(saved: Dictionary) -> void:
	friendships = saved.get("friendships", {}).duplicate()
	talked_on = saved.get("talked_on", {}).duplicate()
	gifted_on = saved.get("gifted_on", {}).duplicate()
