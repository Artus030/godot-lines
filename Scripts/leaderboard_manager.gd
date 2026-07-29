# scripts/leaderboard.gd
class_name LeaderboardManager
extends Node

# Signale für deine UI, damit sie weiß, wenn Daten da sind
signal leaderboard_loaded(entries: Array)
signal score_submitted(success: bool)

const SUPABASE_URL: String = "https://bstflxyqetppyzgqrznv.supabase.co"
const PUBLISHABLE_KEY: String = "sb_publishable_uZs78vohlk9O21UugDP9Qw_POmPTLHY"
const ENDPOINT_URL: String = SUPABASE_URL + "/rest/v1/highscores"

const MAX_ENTRIES: int = 10

# Speichert die aktuell geladenen Einträge: [{"name": "Alex", "score": 1200}, ...]
var leaderboard_data: Array = []


# 1. HIGHSCORES VON SUPABASE LADEN
func load_leaderboard() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_load_completed.bind(http_request))

	var headers = [
		"apikey: " + PUBLISHABLE_KEY,
		"Authorization: Bearer " + PUBLISHABLE_KEY
	]

	# Wir holen Spalten: username (wird als 'name' gemappt) und score
	var url = ENDPOINT_URL + "?select=name:username,score&order=score.desc&limit=" + str(MAX_ENTRIES)
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	if error != OK:
		print("Fehler beim Erstellen der GET-Anfrage: ", error)
		leaderboard_loaded.emit(leaderboard_data)


func _on_load_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest) -> void:
	http_node.queue_free()

	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			leaderboard_data = json.get_data()
			leaderboard_loaded.emit(leaderboard_data)
			return

	print("Fehler beim Laden von Supabase (Code %d)" % response_code)
	leaderboard_loaded.emit([])


# 2. NEUEN HIGHSCORE AN SUPABASE SENDEN
func add_entry(username: String, score: int) -> void:
	if username.strip_edges() == "":
		username = "Spieler"

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_save_completed.bind(http_request))

	var headers = [
		"apikey: " + PUBLISHABLE_KEY,
		"Authorization: Bearer " + PUBLISHABLE_KEY,
		"Content-Type: application/json",
		"Prefer: return=minimal"
	]

	var payload = JSON.stringify({
		"username": username,
		"score": score
	})

	var error = http_request.request(ENDPOINT_URL, headers, HTTPClient.METHOD_POST, payload)
	if error != OK:
		print("Fehler beim Senden der POST-Anfrage: ", error)
		score_submitted.emit(false)


func _on_save_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest) -> void:
	http_node.queue_free()

	# 201 Created bedeutet: Erfolgreich bei Supabase gespeichert
	if response_code == 201:
		score_submitted.emit(true)
		load_leaderboard() # Liste direkt neu von Supabase laden!
	else:
		print("Fehler beim Speichern (Code %d): %s" % [response_code, body.get_string_from_utf8()])
		score_submitted.emit(false)


# 3. HIGHSCORE PRÜFUNG (Nutzt die lokal abgelegten Supabase-Daten)
func is_high_score(score: int) -> bool:
	if score <= 0:
		return false
	if leaderboard_data.size() < MAX_ENTRIES:
		return true
	return score > leaderboard_data[-1]["score"]
