class_name MapPortal
extends Interactable
var target_map_id: String = ""
var target_position: Vector2 = Vector2.ZERO
func interact() -> void:
	EventBus.map_change_requested.emit(target_map_id, target_position)
