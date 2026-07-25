# scripts/leaderboard.gd
class_name LeaderboardManager

const SAVE_PATH = "user://leaderboard.cfg"
const LOCAL_STORAGE_KEY = "lines_leaderboard_data"
const MAX_ENTRIES: int = 10

# Speichert Einträge im Format: [{"name": "Alex", "score": 1200}, ...]
var leaderboard_data: Array = []


func _init():
	load_leaderboard()


func load_leaderboard():
	leaderboard_data = []
	var json_string: String = ""

	# 1. Im Web-Export aus dem Browser-LocalStorage lesen
	if OS.has_feature("web"):
		var result = JavaScriptBridge.eval("localStorage.getItem('%s');" % LOCAL_STORAGE_KEY)
		if result != null:
			json_string = str(result)
	
	# 2. Auf Desktop/Mobil aus der Datei lesen
	else:
		if FileAccess.file_exists(SAVE_PATH):
			var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
			if file:
				json_string = file.get_as_text()
				file.close()

	# JSON-String wieder in ein Array parsen
	if json_string != "":
		var json = JSON.new()
		if json.parse(json_string) == OK and json.data is Array:
			leaderboard_data = json.data


func save_leaderboard():
	# Daten in einen JSON-Text umwandeln
	var json_string = JSON.stringify(leaderboard_data)

	# 1. Im Web-Export in den Browser-LocalStorage schreiben
	if OS.has_feature("web"):
		# Anführungszeichen/Sonderzeichen sicher escapen
		var safe_json = json_string.replace("'", "\\'")
		JavaScriptBridge.eval("localStorage.setItem('%s', '%s');" % [LOCAL_STORAGE_KEY, safe_json])
	
	# 2. Auf Desktop/Mobil in die Datei schreiben
	else:
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_string(json_string)
			file.close()


func is_high_score(score: int) -> bool:
	if score <= 0:
		return false
	# Wenn noch Platz in den Top 10 ist, ist es ein Highscore
	if leaderboard_data.size() < MAX_ENTRIES:
		return true
	# Sonst prüfen, ob der Score besser ist als der schlechteste in den Top 10
	return score > leaderboard_data[-1]["score"]


func add_entry(player_name: String, score: int):
	if player_name.strip_edges() == "":
		player_name = "Spieler"
		
	leaderboard_data.append({
		"name": player_name,
		"score": score
	})
	
	# Nach Score absteigend sortieren
	leaderboard_data.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Nur Top 10 behalten
	if leaderboard_data.size() > MAX_ENTRIES:
		leaderboard_data.resize(MAX_ENTRIES)
		
	save_leaderboard()
