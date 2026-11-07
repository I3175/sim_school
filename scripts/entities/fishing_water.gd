extends Node2D
var zone_id: String = "lake"
var phase: float = 0.0
var rectangle := Rect2(-64, -48, 128, 64)
func _ready() -> void:
	var body := StaticBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rectangle.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rectangle.get_center()
	body.add_child(collision)
	add_child(body)
	var label := Label.new()
	label.text = "J · Câu cá" if zone_id != "sea" else "J · Câu biển"
	label.position = Vector2(-32, 20)
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
func near_shore(location: Vector2) -> bool:
	var local := location - global_position
	return rectangle.grow(24).has_point(local) and not rectangle.has_point(local)
func _process(delta: float) -> void:
	phase += delta
	queue_redraw()
func _draw() -> void:
	var frozen: bool = zone_id == "lake" and GameClock.model.season_index() == 3
	draw_rect(rectangle.grow(2), Color("d8c99a"))
	draw_rect(rectangle, Color("bed8df") if frozen else Color("589db5"))
	var frame := int(phase / 0.4) % 4
	for index in range(6):
		draw_line(Vector2(-52 + index * 20, -20 + frame), Vector2(-44 + index * 20, -20 + frame), Color("a7d6d8"), 1)
