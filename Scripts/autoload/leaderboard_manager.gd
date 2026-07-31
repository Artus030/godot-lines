extends Node

signal leaderboard_loaded
signal score_submitted(success: bool)

const ENDPOINT_PATH: String = "/rest/v1/highscores"
const MAX_ENTRIES: int = 10

var leaderboard_data: Array = []


## Lädt das Leaderboard asynchron und feuert 'leaderboard_loaded'
func load_leaderboard() -> void:
	var query = ENDPOINT_PATH + "?select=name:username,score&order=score.desc&limit=" + str(MAX_ENTRIES)
	
	SupabaseClient.get_db(query, func(code: int, data: Variant):
		print("LEADERBOARD CALLBACK -> Code: ", code, " | Daten-Typ: ", typeof(data))
		
		if code == 200 and data is Array:
			leaderboard_data = data
			print("Daten erfolgreich gespeichert! Anzahl Einträge: ", leaderboard_data.size())
		else:
			leaderboard_data = []
			print("Fehler beim Verarbeiten der Daten!")
		
		# Das Signal abfeuern, damit das UI aufwacht
		print("Feuere Signal: leaderboard_loaded")
		leaderboard_loaded.emit() 
	)


## Sendet einen neuen Score und aktualisiert danach automatisch das Leaderboard
func add_entry(username: String, score: int) -> void:
	var clean_name = username.strip_edges()
	if clean_name.is_empty():
		clean_name = "Spieler"

	var payload = {
		"username": clean_name,
		"score": score
	}

	SupabaseClient.post_db(ENDPOINT_PATH, payload, func(code: int, _data: Variant):
		var is_success = (code == 201)
		score_submitted.emit(is_success)
		
		if is_success:
			# Direkt die frischen Daten aus der DB nachladen!
			load_leaderboard()
		else:
			push_error("Score konnte nicht gesendet werden. Code: " + str(code))
	)


## Prüft lokal, ob ein Score in die Top-Liste einzieht
func is_high_score(score: int) -> bool:
	if score <= 0:
		return false
	if leaderboard_data.is_empty() or leaderboard_data.size() < MAX_ENTRIES:
		return true
	
	# Vergleicht mit dem niedrigsten Score in der aktuellen Top-Liste
	return score > leaderboard_data[-1].get("score", 0)
