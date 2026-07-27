class_name PersistenceManager
extends Node

const SAVE_PATH = "user://game_data.json"

## Speichert ein beliebiges Dictionary oder Array unter einem bestimmten Key ab
static func save_data(key: String, value: Variant) -> void:
	var current_data = _load_all_data()
	current_data[key] = value
	_write_all_data(current_data)


## Lädt die Daten für einen Key. Gibt default_value zurück, falls der Key nicht existiert.
static func load_data(key: String, default_value: Variant = null) -> Variant:
	var current_data = _load_all_data()
	if current_data.has(key):
		return current_data[key]
	return default_value


## Löscht einen bestimmten Key aus dem Speicher
static func erase_key(key: String) -> void:
	var current_data = _load_all_data()
	if current_data.has(key):
		current_data.erase(key)
		_write_all_data(current_data)


# --- Interne Hilfsfunktionen ---

static func _load_all_data() -> Dictionary:
	var json_string: String = ""

	if OS.has_feature("web"):
		# In Web liest er alles aus einem zentralen App-Key
		var result = JavaScriptBridge.eval("localStorage.getItem('game_save_data');")
		if result != null:
			json_string = str(result)
	else:
		if FileAccess.file_exists(SAVE_PATH):
			var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
			if file:
				json_string = file.get_as_text()
				file.close()

	if json_string == "":
		return {}

	var json = JSON.new()
	if json.parse(json_string) == OK and json.data is Dictionary:
		return json.data

	return {}


static func _write_all_data(data: Dictionary) -> void:
	var json_string = JSON.stringify(data)

	if OS.has_feature("web"):
		# Sicheres Escaping für JavaScript-Strings (Backslashes und Anführungszeichen)
		var safe_json = json_string.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")
		JavaScriptBridge.eval("localStorage.setItem('game_save_data', '%s');" % safe_json)
	else:
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_string(json_string)
			file.close()
