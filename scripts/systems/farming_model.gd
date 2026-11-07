class_name FarmingModel
extends RefCounted
var crops: Dictionary = {}
var cells: Dictionary = {}
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/farming.json"))
var farming_xp: int = 0
var shipping: Array[Dictionary] = []
var last_day: int = 0
var world_seed: int = 20261107

func _init() -> void:
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops/catalog.json"))
	for id: String in catalog:
		crops[id] = load("res://data/crops/%s.tres" % id)

func till(key: String) -> bool:
	if cells.has(key):
		return false
	cells[key] = {"watered": false, "crop": "", "growth": 0, "dry_days": 0, "withered": false, "fertilizer": "", "sheltered": false, "water_streak": 0, "retained": false}
	return true

func plant(key: String, id: String, season: int, sheltered: bool = false) -> bool:
	if not cells.has(key) or not crops.has(id):
		return false
	var crop: CropData = crops[id]
	var cell: Dictionary = cells[key]
	if cell.crop != "" or (not sheltered and (season not in crop.seasons or crop.requires_shelter)):
		return false
	cell.crop = id
	cell.growth = 0
	cell.dry_days = 0
	cell.withered = false
	cell.sheltered = sheltered
	return true

func water(key: String) -> bool:
	if not cells.has(key) or bool(cells[key].watered):
		return false
	cells[key].watered = true
	return true

func rain() -> void:
	for cell: Dictionary in cells.values():
		if not bool(cell.sheltered):
			cell.watered = true

func advance_day(new_day: int, new_season: int, raining: bool) -> void:
	if new_day <= last_day:
		return
	for day in range(last_day + 1, new_day + 1):
		for cell: Dictionary in cells.values():
			if cell.crop != "" and not bool(cell.withered):
				var crop: CropData = crops[cell.crop]
				if bool(cell.watered):
					cell.growth = int(cell.growth) + 1
					cell.dry_days = 0
					cell.water_streak = int(cell.get("water_streak", 0)) + 1
				else:
					cell.dry_days = int(cell.dry_days) + 1
					cell.water_streak = 0
				if int(cell.dry_days) >= int(rules.dry_days_to_wilt) or (not bool(cell.sheltered) and new_season not in crop.seasons):
					cell.withered = true
			var retain: bool = cell.fertilizer == "retention" and bool(cell.watered) and not bool(cell.get("retained", false))
			cell.retained = retain
			cell.watered = retain or (bool(cell.sheltered) == false and raining)
	last_day = new_day

func mature(key: String) -> bool:
	if not cells.has(key) or cells[key].crop == "" or bool(cells[key].withered):
		return false
	var crop: CropData = crops[cells[key].crop]
	var required_days: int = maxi(2, crop.growth_days - (1 if cells[key].fertilizer == "growth" else 0))
	return int(cells[key].growth) >= required_days

func harvest(key: String, quality: int = 0) -> Dictionary:
	if not mature(key):
		return {}
	var cell: Dictionary = cells[key]
	var crop: CropData = crops[cell.crop]
	var result := {"id": crop.harvest_id, "amount": 1, "quality": quality, "xp": crop.farming_xp}
	farming_xp += crop.farming_xp
	if crop.regrow_days > 0:
		cell.growth = crop.growth_days - crop.regrow_days
	else:
		cell.crop = ""
		cell.growth = 0
	return result

func snapshot() -> Dictionary:
	return {"cells": cells.duplicate(true), "shipping": shipping.duplicate(true), "farming_xp": farming_xp, "last_day": last_day}

func valid_snapshot(saved: Variant) -> bool:
	if not saved is Dictionary or not saved.get("cells") is Dictionary or not saved.get("shipping") is Array:
		return false
	for key: String in saved.cells:
		var parts := key.split(",")
		if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
			return false
		var cell: Variant = saved.cells[key]
		if not cell is Dictionary or not cell.has_all(["watered", "crop", "growth", "dry_days", "withered", "fertilizer", "sheltered"]):
			return false
		if cell.crop != "" and not crops.has(cell.crop):
			return false
		if not (cell.growth is float or cell.growth is int) or not (cell.dry_days is float or cell.dry_days is int):
			return false
		if float(cell.growth) < 0 or float(cell.dry_days) < 0:
			return false
		if not cell.watered is bool or not cell.withered is bool or not cell.sheltered is bool:
			return false
	return true

func restore(saved: Dictionary) -> void:
	cells = saved.cells.duplicate(true)
	for cell: Dictionary in cells.values():
		cell.growth = int(cell.growth)
		cell.dry_days = int(cell.dry_days)
		cell.water_streak = int(cell.get("water_streak", 0))
	shipping.assign(saved.shipping.duplicate(true))
	farming_xp = int(saved.get("farming_xp", 0))
	last_day = int(saved.get("last_day", 0))

func fertilize(key: String, kind: String) -> bool:
	if not cells.has(key) or kind not in ["quality", "growth", "retention"] or cells[key].fertilizer != "":
		return false
	cells[key].fertilizer = kind
	return true

func harvest_quality(_key: String, _skill_level: int = 1, _luck: float = 0.0) -> int:
	# User will supply the quality formula. Neutral quality until then.
	return 0
