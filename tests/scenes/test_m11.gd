extends "res://scripts/core/main.gd"
func _ready() -> void:
	super._ready()
	EventBus.study_requested.emit(true)
