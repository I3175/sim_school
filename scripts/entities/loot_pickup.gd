extends Node2D
var record: Dictionary
var retry: float = 0.0
func _ready() -> void:
	position = Vector2(float(record.x), float(record.y))
	var sprite := Sprite2D.new()
	sprite.texture = ItemDatabase.get_item(str(record.item.id)).icon
	sprite.position.y = -8
	add_child(sprite)
func _process(delta: float) -> void:
	retry -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if retry > 0 or player == null or position.distance_to(player.position) > 24:
		return
	retry = 0.5
	var response := {}
	EventBus.inventory_transaction_requested.emit({"add": [record.item]}, response)
	if response.get("success", false):
		record.collected = true
		queue_free()
