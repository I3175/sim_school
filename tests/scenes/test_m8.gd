extends "res://scripts/core/main.gd"
func _ready() -> void:
	super._ready()
	InventoryManager.add("sword", 1)
	InventoryManager.selected_slot = 3
	SceneManager.flags.mine_unlocked = true
	SceneManager._activate("stone_mine", Vector2(320, 240))
