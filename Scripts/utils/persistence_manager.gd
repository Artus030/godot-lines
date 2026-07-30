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
	var json_string: String = ""

	if OS.has_feature("web"):
		var result = JavaScriptBridge.eval("localStorage.getItem('game_save_data');")
		if result != null:
			json_string = str(result)
	else:
		if FileAccess.file_exists(SAVE_PATH):
			var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
			if file:
				json_string = file.get_as_text()
				file.close()

	if json_string.is_empty():
		return {}

	var json = JSON.new()
	if json.parse(json_string) == OK and json.data is Dictionary:
		return json.data

	return {}


static func _write_to_disk() -> void:
	var json_string = JSON.stringify(_cache)

	if OS.has_feature("web"):
		var safe_json = json_string.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")
		JavaScriptBridge.eval("localStorage.setItem('game_save_data', '%s');" % safe_json)
	else:
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_string(json_string)
			file.close()
