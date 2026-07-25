# scripts/leaderboard.gd
class_name LeaderboardManager

const SAVE_PATH = "user://leaderboard.cfg"
const MAX_ENTRIES: int = 10

# Speichert Einträge im Format: [{"name": "Alex", "score": 1200}, ...]
var leaderboard_data: Array = []


func _init():
	load_leaderboard()


func load_leaderboard():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	if error == OK:
		leaderboard_data = config.get_value("Leaderboard", "scores", [])
	else:
		leaderboard_data = []


func save_leaderboard():
	var config = ConfigFile.new()
	config.set_value("Leaderboard", "scores", leaderboard_data)
	config.save(SAVE_PATH)


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
