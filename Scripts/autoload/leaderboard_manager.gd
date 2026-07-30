extends Node

signal leaderboard_loaded(entries: Array)
signal score_submitted(success: bool)

const ENDPOINT_PATH: String = "/rest/v1/highscores"
const MAX_ENTRIES: int = 10

var leaderboard_data: Array = []


func load_leaderboard() -> void:
	var query = ENDPOINT_PATH + "?select=name:username,score&order=score.desc&limit=" + str(MAX_ENTRIES)
	
	SupabaseClient.get_db(query, func(code: int, data: Variant):
		if code == 200 and data is Array:
			leaderboard_data = data
			leaderboard_loaded.emit(leaderboard_data)
		else:
			leaderboard_loaded.emit([])
	)


func add_entry(username: String, score: int) -> void:
	var clean_name = username.strip_edges()
	if clean_name.is_empty():
		clean_name = "Spieler"

	var payload = {
		"username": clean_name,
		"score": score
	}

	SupabaseClient.post_db(ENDPOINT_PATH, payload, func(code: int, data: Variant):
		if code == 201:
			score_submitted.emit(true)
			load_leaderboard()
		else:
			score_submitted.emit(false)
	)


func is_high_score(score: int) -> bool:
	if score <= 0 or leaderboard_data.is_empty():
		return false
	if leaderboard_data.size() < MAX_ENTRIES:
		return true
	return score > leaderboard_data[-1].get("score", 0)
