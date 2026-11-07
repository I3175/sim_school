extends Node2D

const ART_ROOT := "res://assets/art/sao_mai/farm/"
const GROUND_ATLAS := preload("res://assets/art/sao_mai/farm/spring-ground.png")
const PLAYER := preload("res://scenes/entities/player/player.tscn")

@export var spawn_player: bool = true
var player: VillagePlayer

func _ready() -> void:
	var bundle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART_ROOT + "map-bundle.json"))
	_create_ground(bundle.tile_size)
	for object: Dictionary in bundle.objects:
		var prop: Dictionary = bundle.props[object.prop]
		var footprint: Dictionary = object.footprint
		var texture := load(ART_ROOT + str(prop.image)) as Texture2D
		_add_prop(Vector2(object.x, object.y), texture, Vector2(object.anchor_px[0], object.anchor_px[1]),
			Vector2(footprint.width, footprint.depth), Vector2(footprint.offset[0], footprint.offset[1]))
	if spawn_player:
		var spawn: Dictionary = bundle.spawns[0]
		player = PLAYER.instantiate()
		player.position = Vector2(spawn.x, spawn.y)
		$Entities.add_child(player)
	for boundary: Array in bundle.collision.rects:
		var rect := Rect2(boundary[0], boundary[1], boundary[2], boundary[3])
		var wall := StaticBody2D.new()
		wall.position = rect.get_center()
		_add_rectangle(wall, rect.size, Vector2.ZERO)
		add_child(wall)

func _create_ground(tile_size: int) -> void:
	var tile_size_px := Vector2i(tile_size, tile_size)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = GROUND_ATLAS
	atlas.texture_region_size = tile_size_px
	var atlas_grid := atlas.get_atlas_grid_size()
	for y in range(atlas_grid.y):
		for x in range(atlas_grid.x):
			atlas.create_tile(Vector2i(x, y))
	var tile_set := TileSet.new()
	tile_set.tile_size = tile_size_px
	tile_set.add_source(atlas, 0)
	$Ground.tile_set = tile_set
	var grid: Array = JSON.parse_string(FileAccess.get_file_as_string(ART_ROOT + "ground-tiles.json"))
	for y in range(grid.size()):
		var row: Array = grid[y]
		for x in range(row.size()):
			var index := int(row[x])
			@warning_ignore("integer_division")
			var coordinate := Vector2i(index % atlas_grid.x, index / atlas_grid.x)
			$Ground.set_cell(Vector2i(x, y), 0, coordinate)

func _add_prop(location: Vector2, texture: Texture2D, anchor: Vector2, size_px: Vector2, offset: Vector2) -> void:
	var prop := StaticBody2D.new()
	prop.position = location
	prop.collision_layer = 1
	prop.collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = -anchor
	prop.add_child(sprite)
	_add_rectangle(prop, size_px, offset)
	$Entities.add_child(prop)

func _add_rectangle(body: StaticBody2D, size_px: Vector2, offset: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size_px
	collision.shape = shape
	collision.position = offset
	body.add_child(collision)
