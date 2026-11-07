class_name QuestModel
extends RefCounted
var definitions: Dictionary = {}
var states: Dictionary = {}
var pinned: Array[String] = []

func _init() -> void:
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests/catalog.json"))
	for id: String in catalog:
		definitions[id] = load("res://data/quests/%s.tres" % id)
		states[id] = {"status": "Locked", "progress": [], "accepted_day": -1, "claimed_day": -1}

func refresh(context: Dictionary) -> void:
	var day: int = int(context.get("day", 0))
	for id: String in definitions:
		var quest: QuestData = definitions[id]
		var state: Dictionary = states[id]
		if state.status in ["Active", "Ready"] and quest.quest_type != "main" and quest.time_limit_days > 0 and day >= int(state.accepted_day) + quest.time_limit_days:
			state.status = "Expired"
		if quest.repeatable and state.status in ["Claimed", "Expired"] and day >= maxi(int(state.claimed_day), int(state.accepted_day)) + quest.cooldown_days:
			state.status = "Locked"
		if state.status == "Locked" and _eligible(quest, context):
			state.status = "Available"

func _eligible(quest: QuestData, context: Dictionary) -> bool:
	var requirements := quest.prerequisites
	if requirements.has("flag") and not context.get("flags", {}).get(requirements.flag, false):
		return false
	if requirements.get("festival", false) and int(context.get("day", 0)) % 7 != 6:
		return false
	if requirements.has("discover") and requirements.discover not in context.get("discovered", []):
		return false
	if requirements.has("friendship"):
		var friendship: Dictionary = requirements.friendship
		if int(context.get("friendships", {}).get(friendship.npc, 0)) < int(friendship.points):
			return false
	return true

func accept(id: String, day: int) -> bool:
	if not states.has(id) or states[id].status != "Available":
		return false
	var quest: QuestData = definitions[id]
	var state: Dictionary = states[id]
	state.status = "Active"
	state.accepted_day = day
	state.progress = []
	for objective in quest.objectives:
		state.progress.append(0)
	if quest.quest_type == "main" and pinned.size() < 3 and id not in pinned:
		pinned.append(id)
	return true

func record(event: String, target: String, amount: int = 1) -> void:
	for id: String in definitions:
		if states[id].status != "Active":
			continue
		var quest: QuestData = definitions[id]
		var state: Dictionary = states[id]
		for index in range(quest.objectives.size()):
			var objective := quest.objectives[index]
			if objective.type == event and objective.target == target:
				state.progress[index] = mini(int(objective.amount), int(state.progress[index]) + maxi(0, amount))
			if quest.sequential and int(state.progress[index]) < int(objective.amount) and not objective.get("optional", false):
				break
		var ready := true
		for index in range(quest.objectives.size()):
			var objective := quest.objectives[index]
			if not objective.get("optional", false) and int(state.progress[index]) < int(objective.amount):
				ready = false
		if ready:
			state.status = "Ready"

func claim(id: String, day: int) -> Dictionary:
	if not states.has(id) or states[id].status != "Ready":
		return {}
	states[id].status = "Claimed"
	states[id].claimed_day = day
	pinned.erase(id)
	return (definitions[id] as QuestData).rewards.duplicate(true)

func pin(id: String) -> void:
	if id in pinned:
		pinned.erase(id)
	elif pinned.size() < 3 and states.get(id, {}).get("status", "") in ["Active", "Ready"]:
		pinned.append(id)

func snapshot() -> Dictionary:
	return {"states": states.duplicate(true), "pinned": pinned.duplicate()}

func restore(saved: Dictionary) -> void:
	var saved_states: Dictionary = saved.get("states", {})
	for id: String in definitions:
		if saved_states.has(id):
			states[id] = saved_states[id].duplicate(true)
	pinned.assign(saved.get("pinned", []))
