extends Node2D
var definition: Dictionary = {}
const ATLAS = preload("res://assets/topdown-16x16/tiny-town/Tilemap/tilemap_packed.png")

func _ready() -> void:
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.z_index = -2
	var source := TileSetAtlasSource.new()
	source.texture = ATLAS
	source.texture_region_size = Vector2i(16, 16)
	var coordinate := Vector2i(0, 4) if definition.get("indoors", false) else Vector2i(0, 0)
	source.create_tile(coordinate)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	tile_set.add_source(source, 0)
	ground.tile_set = tile_set
	add_child(ground)
	var dimensions: Array = definition.size
	for y in range(int(dimensions[1])):
		for x in range(int(dimensions[0])):
			ground.set_cell(Vector2i(x, y), 0, coordinate)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	var label := Label.new()
	label.text = str(definition.name)
	label.position = Vector2(float(definition.spawn[0]) - 40, float(definition.spawn[1]) - 60)
	label.add_theme_font_size_override("font_size", 10)
	add_child(label)
	var width := float(dimensions[0]) * 16.0
	var height := float(dimensions[1]) * 16.0
	for rectangle: Rect2 in [Rect2(0, 0, width, 8), Rect2(0, height - 8, width, 8), Rect2(0, 0, 8, height), Rect2(width - 8, 0, 8, height)]:
		var wall := StaticBody2D.new()
		wall.position = rectangle.get_center()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rectangle.size
		collision.shape = shape
		wall.add_child(collision)
		add_child(wall)
