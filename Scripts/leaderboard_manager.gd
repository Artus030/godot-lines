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
	leaderboard_data = PersistenceManager.load_data(LOCAL_STORAGE_KEY, [])


func save_leaderboard():
	PersistenceManager.save_data(LOCAL_STORAGE_KEY, leaderboard_data)
	
	
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

	leaderboard_data.sort_custom(func(a, b): return a["score"] > b["score"])

	if leaderboard_data.size() > MAX_ENTRIES:
		leaderboard_data.resize(MAX_ENTRIES)

	save_leaderboard()
