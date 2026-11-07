class_name Interactable
extends Area2D
@export var persistent_id: String = ""
@export var prompt: String = "Tương tác"
@export var interaction_priority: int = 1
var action: Callable

func _ready() -> void:
	collision_layer = 32
	collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	collision.shape = shape
	add_child(collision)
	var label := Label.new()
	label.text = "E · " + prompt
	label.position = Vector2(-20, -23)
	label.add_theme_font_size_override("font_size", 7)
	add_child(label)

func interact() -> void:
	if action.is_valid():
		action.call()
	EventBus.interacted_with.emit(persistent_id)
