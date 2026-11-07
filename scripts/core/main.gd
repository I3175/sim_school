extends Node
const PLAYER = preload("res://scenes/entities/player/player.tscn")
func _ready() -> void:
	var player: VillagePlayer = PLAYER.instantiate()
	$Maps.add_child(player)
	SceneManager.configure($Maps, player, $Transition/Curtain)

func _exit_tree() -> void:
	for map: Node in SceneManager.cache.values():
		if is_instance_valid(map) and map.get_parent() == null:
			map.free()
	SceneManager.cache.clear()
	SceneManager.host = null
	SceneManager.player = null
