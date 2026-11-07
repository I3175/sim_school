class_name InventoryModel
extends RefCounted
var catalog: Dictionary
var slots: Array[Dictionary] = []
func _init(item_catalog: Dictionary = {}, capacity: int = 36) -> void:
	catalog = item_catalog
	for index in range(capacity):
		slots.append({})

func add(id: String, amount: int, quality: int = 0) -> int:
	if not catalog.has(id) or amount <= 0 or quality < 0 or quality > 3:
		return maxi(amount, 0)
	var item: ItemData = catalog[id]
	if not item.quality_enabled and quality != 0:
		return amount
	var remaining := amount
	for slot: Dictionary in slots:
		if slot.get("id", "") == id and int(slot.get("quality", 0)) == quality:
			var accepted := mini(remaining, item.stack_size - int(slot.amount))
			slot.amount = int(slot.amount) + accepted
			remaining -= accepted
	for index in range(slots.size()):
		if remaining == 0:
			break
		if slots[index].is_empty():
			var accepted := mini(remaining, item.stack_size)
			slots[index] = {"id": id, "amount": accepted, "quality": quality}
			remaining -= accepted
	return remaining

func move_to(source_index: int, target: InventoryModel, target_index: int, amount: int = -1) -> bool:
	if source_index < 0 or source_index >= slots.size() or target_index < 0 or target_index >= target.slots.size():
		return false
	if self == target and source_index == target_index:
		return false
	var source: Dictionary = slots[source_index]
	if source.is_empty():
		return false
	var count := int(source.amount) if amount < 0 else mini(amount, int(source.amount))
	if count <= 0:
		return false
	var destination: Dictionary = target.slots[target_index]
	if destination.is_empty():
		target.slots[target_index] = source.duplicate()
		target.slots[target_index].amount = count
	elif destination.id == source.id and int(destination.quality) == int(source.quality):
		count = mini(count, (catalog[source.id] as ItemData).stack_size - int(destination.amount))
		if count <= 0:
			return false
		destination.amount = int(destination.amount) + count
	else:
		if count != int(source.amount):
			return false
		slots[source_index] = destination
		target.slots[target_index] = source
		return true
	source.amount = int(source.amount) - count
	if int(source.amount) == 0:
		slots[source_index] = {}
	return true

func remove(id: String, amount: int, quality: int = -1) -> bool:
	if amount <= 0 or count(id, quality) < amount:
		return false
	var remaining := amount
	for index in range(slots.size()):
		var slot := slots[index]
		if slot.get("id", "") != id or (quality >= 0 and int(slot.get("quality", 0)) != quality):
			continue
		var taken := mini(remaining, int(slot.amount))
		slot.amount = int(slot.amount) - taken
		remaining -= taken
		if int(slot.amount) == 0:
			slots[index] = {}
		if remaining == 0:
			break
	return true

func count(id: String, quality: int = -1) -> int:
	var total := 0
	for slot: Dictionary in slots:
		if slot.get("id", "") == id and (quality < 0 or int(slot.get("quality", 0)) == quality):
			total += int(slot.amount)
	return total

func valid_snapshot(data: Variant) -> bool:
	if not data is Array or data.size() != slots.size():
		return false
	for slot: Variant in data:
		if not slot is Dictionary:
			return false
		if slot.is_empty():
			continue
		if not catalog.has(slot.get("id", "")) or not slot.has_all(["amount", "quality"]):
			return false
		var item: ItemData = catalog[slot.id]
		if not (slot.amount is int or slot.amount is float) or float(slot.amount) != floorf(float(slot.amount)):
			return false
		if int(slot.amount) <= 0 or int(slot.amount) > item.stack_size:
			return false
		if not (slot.quality is int or slot.quality is float) or float(slot.quality) != floorf(float(slot.quality)):
			return false
		if int(slot.quality) < 0 or int(slot.quality) > 3 or (not item.quality_enabled and int(slot.quality) != 0):
			return false
	return true

func restore(data: Array) -> bool:
	if not valid_snapshot(data):
		return false
	slots.assign(data.duplicate(true))
	return true

func sort_items() -> void:
	var original := slots.duplicate(true)
	original.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("id", "~")) < str(b.get("id", "~")))
	for index in range(slots.size()):
		slots[index] = {}
	for slot: Dictionary in original:
		if not slot.is_empty():
			add(str(slot.id), int(slot.amount), int(slot.quality))
