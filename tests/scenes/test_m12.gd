extends "res://scripts/core/main.gd"
func _ready() -> void:
	super._ready()
	$StoryJournal.set_open.call_deferred(true)
