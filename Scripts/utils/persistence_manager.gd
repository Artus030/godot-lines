class_name PersistenceManager
extends RefCounted

const SAVE_PATH = "user://game_data.json"

static var _cache: Dictionary = {}
static var _is_initialized: bool = false


static func save_data(key: String, value: Variant) -> void:
	_ensure_loaded()
	_cache[key] = value
	_write_to_disk()


static func load_data(key: String, default_value: Variant = null) -> Variant:
	_ensure_loaded()
	return _cache.get(key, default_value)


static func validate_board_data(grid_dict: Variant, current_cols: int, current_rows: int) -> Variant:
	if grid_dict is Dictionary:
		var saved_cols = grid_dict.get("cols", -1)
		var saved_rows = grid_dict.get("rows", -1)
		
		if saved_cols == current_cols and saved_rows == current_rows:
			return grid_dict
			
	return null


static func erase_key(key: String) -> void:
	_ensure_loaded()
	if _cache.has(key):
		_cache.erase(key)
		_write_to_disk()


static func _ensure_loaded() -> void:
	if _is_initialized:
		return
		
	_is_initialized = true
	_cache = _read_from_disk()


static func _read_from_disk() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	if json_string.is_empty():
		return {}

	var json = JSON.new()
	if json.parse(json_string) == OK and json.data is Dictionary:
		return json.data

	return {}


static func _write_to_disk() -> void:
	var json_string = JSON.stringify(_cache)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
