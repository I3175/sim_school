extends "res://scripts/core/main.gd"
func _ready() -> void:
	super._ready()
	# Isolated encounter fixture; does not award chapters in the normal game.
	StoryManager.model.completed = 1
	GameClock.model.total_minutes = 3 * 1440 + 600
	SceneManager._activate("school", Vector2(104, 136))
	$ZeroEncounter.open.call_deferred()
