extends Node
var items: Dictionary = {}
func _ready() -> void:
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/catalog.json"))
	for id: String in catalog:
		var item: ItemData = load("res://data/items/%s.tres" % id)
		items[item.id] = item
func get_item(id: String) -> ItemData:
	return items.get(id)
