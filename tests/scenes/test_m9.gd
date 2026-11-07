extends "res://scripts/core/main.gd"
func _ready() -> void:
	super._ready()
	$AnimalSystem.model.buildings = {"coop": true, "barn": true}
	$AnimalSystem.model.add("chicken")
	$AnimalSystem.model.add("cow")
	$AnimalSystem.model.hay = 100
	$AnimalSystem.model.water = 100
	SceneManager._activate("coop", Vector2(192, 208))
