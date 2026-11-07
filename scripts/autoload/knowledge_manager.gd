extends Node
var model := KnowledgeModel.new()
var puzzle_failures: Dictionary = {}
func _ready() -> void:
	EventBus.state_save_requested.connect(func(state: Dictionary) -> void: state.knowledge = model.snapshot(); state.knowledge.puzzle_failures = puzzle_failures.duplicate())
	EventBus.state_load_requested.connect(func(state: Dictionary) -> void: model.restore(state.get("knowledge", {})); puzzle_failures = state.get("knowledge", {}).get("puzzle_failures", {}).duplicate())

func finish(subject: String, correct_count: int, total: int, tier: int, practice: bool) -> Dictionary:
	var day := GameClock.model.day_index()
	var result := model.finish(subject, correct_count, total, tier, day, practice)
	if not practice:
		EventBus.resident_xp_awarded.emit(int(result.resident_xp))
		if result.daily_reward:
			var response := {}
			EventBus.inventory_transaction_requested.emit({"add": [model.rules.daily_reward]}, response)
			if response.get("success", false):
				model.daily_reward[subject] = day
		EventBus.knowledge_session_finished.emit(subject, int(result.stars))
	return result

func story_puzzle_result(id: String, stars: int) -> int:
	if stars > 0:
		return stars
	puzzle_failures[id] = int(puzzle_failures.get(id, 0)) + 1
	return 1 if int(puzzle_failures[id]) >= 3 else 0
