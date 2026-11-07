extends Node2D
const ATLAS = preload("res://assets/topdown-16x16/tiny-town/Tilemap/tilemap_packed.png")
const PLAYER = preload("res://scenes/entities/player/player.tscn")
var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/farm_layout.json"))
@export var spawn_player: bool = true
var player: VillagePlayer

func _ready() -> void:
	_create_ground()
	_create_chest()
	for location: Array in layout.trees:
		_add_prop(Vector2(float(location[0]), float(location[1])), Rect2(64, 0, 16, 32), Vector2(8, 6))
	for location: Array in layout.rocks:
		_add_prop(Vector2(float(location[0]), float(location[1])), Rect2(96, 32, 16, 16), Vector2(12, 8))
	var house: Array = layout.house
	_add_prop(Vector2(float(house[0]), float(house[1])), Rect2(0, 64, 48, 48), Vector2(44, 14))
	if spawn_player:
		player = PLAYER.instantiate()
		player.position = Vector2(float(layout.spawn[0]), float(layout.spawn[1]))
		$Entities.add_child(player)
	_create_boundary(Rect2(0, 0, 1280, 8))
	_create_boundary(Rect2(0, 952, 1280, 8))
	_create_boundary(Rect2(0, 0, 8, 960))
	_create_boundary(Rect2(1272, 0, 8, 960))

func _create_ground() -> void:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ATLAS
	atlas.texture_region_size = Vector2i(16, 16)
	for coordinate in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 2)]:
		atlas.create_tile(coordinate)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	tile_set.add_source(atlas, 0)
	$Ground.tile_set = tile_set
	for y in range(int(layout.size[1])):
		for x in range(int(layout.size[0])):
			var coordinate := Vector2i(1, 0) if (x * 7 + y * 11) % 19 == 0 else Vector2i(0, 0)
			if x in range(39, 42) or y in range(29, 32):
				coordinate = Vector2i(1, 2)
			$Ground.set_cell(Vector2i(x, y), 0, coordinate)

func _add_prop(location: Vector2, region: Rect2, footprint: Vector2) -> void:
	var prop := StaticBody2D.new()
	prop.position = location
	prop.collision_layer = 1
	prop.collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = ATLAS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = Vector2(0, -region.size.y / 2)
	prop.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = footprint
	collision.shape = shape
	collision.position.y = -footprint.y / 2
	prop.add_child(collision)
	$Entities.add_child(prop)

func _create_boundary(rectangle: Rect2) -> void:
	var wall := StaticBody2D.new()
	wall.position = rectangle.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rectangle.size
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)

func _create_chest() -> void:
	var chest := StaticBody2D.new()
	chest.position = Vector2(680, 480)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/art/props/chest.svg")
	sprite.position.y = -8
	chest.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 8)
	collision.shape = shape
	collision.position.y = -4
	chest.add_child(collision)
	$Entities.add_child(chest)
