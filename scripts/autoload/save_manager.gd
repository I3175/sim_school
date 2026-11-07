extends Node
var store := SaveStore.new()
func _ready() -> void:
	EventBus.save_requested.connect(save_slot)
	EventBus.load_requested.connect(load_slot)

func save_slot(slot: int) -> bool:
	var state: Dictionary = {"meta": {"saved_at": Time.get_datetime_string_from_system()}, "maps": {}, "quests": {}, "npcs": {}, "knowledge": {}, "flags": {}}
	EventBus.state_save_requested.emit(state)
	var success := store.write_slot(slot, state)
	EventBus.save_finished.emit(success, "Đã lưu ô %d" % (slot + 1) if success else store.last_error)
	return success

func load_slot(slot: int) -> bool:
	var state := store.read_slot(slot)
	if state.is_empty():
		EventBus.save_finished.emit(false, store.last_error)
		return false
	var errors: Array = []
	EventBus.state_validate_requested.emit(state, errors)
	if not errors.is_empty():
		EventBus.save_finished.emit(false, str(errors[0]))
		return false
	EventBus.state_load_requested.emit(state)
	EventBus.state_restored.emit()
	EventBus.save_finished.emit(true, "Đã tải ô %d" % (slot + 1))
	return true
