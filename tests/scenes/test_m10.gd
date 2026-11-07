extends "res://scripts/core/main.gd"
func _ready() -> void:
	super._ready()
	InventoryManager.add("bamboo_rod", 1)
	InventoryManager.add("crab_trap", 1)
	InventoryManager.add("bait", 5)
	InventoryManager.selected_slot = 3
	SceneManager._activate("mirror_lake", Vector2(640, 310))
