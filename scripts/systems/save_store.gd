class_name SaveStore
extends RefCounted
const VERSION: int = 1
var directory: String = "user://saves"
var last_error: String = ""

func write_slot(slot: int, state: Dictionary) -> bool:
	if slot < 0 or slot > 2:
		last_error = "Ô lưu phải từ 1 đến 3"
		return false
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		last_error = "Không tạo được thư mục lưu"
		return false
	var path := "%s/slot_%d.json" % [directory, slot]
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Không ghi được bản lưu"
		return false
	var payload := state.duplicate(true)
	payload.save_version = VERSION
	file.store_string(JSON.stringify(payload))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_error = "Ghi bản lưu thất bại"
		return false
	if FileAccess.file_exists(path):
		var backup := path + ".bak"
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(path, backup) != OK:
			last_error = "Không tạo được bản dự phòng"
			return false
	if DirAccess.rename_absolute(temporary, path) != OK:
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.rename_absolute(path + ".bak", path)
		last_error = "Không thay được bản lưu"
		return false
	last_error = ""
	return true

func read_slot(slot: int) -> Dictionary:
	last_error = ""
	if slot < 0 or slot > 2:
		last_error = "Ô lưu không hợp lệ"
		return {}
	var path := "%s/slot_%d.json" % [directory, slot]
	if not FileAccess.file_exists(path):
		last_error = "Ô lưu trống"
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		last_error = "Bản lưu JSON bị hỏng"
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("save_version") != VERSION:
		last_error = "Bản lưu hỏng hoặc khác phiên bản"
		return {}
	return parsed
