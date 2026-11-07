extends Node
var season_index: int = 0
func _ready() -> void:
	EventBus.season_changed.connect(_on_season_changed)
func _on_season_changed(index: int) -> void:
	season_index = index
