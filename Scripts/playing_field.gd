extends Node2D

@export var ball_scene: PackedScene
@onready var ui_manager = $UILayer

# 1. Konstanten nach oben ziehen oder Variable erst in _ready() befüllen
const COLUMNS: int = 10
const ROWS: int = 10
const TILE_SIZE: int = 50

const COLORS: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN,
	Color.YELLOW, Color.PURPLE, Color.ORANGE
]

# Das GameBoard verfaltet die komplette Grid-Logik
var game_board: GameBoard
var is_game_over: bool = false
var score: int = 0
var selected_ball: Ball = null
var next_colors: Array[Color] = []
var leaderboard_manager: LeaderboardManager = null


func _ready():
	# GameBoard etc. instanziieren
	game_board = GameBoard.new(COLUMNS, ROWS, TILE_SIZE)
	leaderboard_manager = LeaderboardManager.new()
	
	ui_manager.restart_requested.connect(_on_restart_button_pressed)
	get_tree().root.size_changed.connect(calculate_center_offset)
	
	generate_next_colors(3)
	spawn_random_balls(5)
	ui_manager.update_score(score)

	# NEU: Ein ganz kurzer Delay (2 Frames warten),
	# damit Firefox Mobile den Canvas & das WebGL-Context sicher initialisiert hat!
	await get_tree().process_frame
	await get_tree().process_frame
	calculate_center_offset()


func calculate_center_offset():
	var visible_size = get_viewport().get_visible_rect().size
	
	var grid_pixel_width = COLUMNS * TILE_SIZE
	var grid_pixel_height = ROWS * TILE_SIZE
	
	var target_scale = 1.0
	
	if visible_size.x < visible_size.y:
		# Hochformat (Handy)
		var target_width = visible_size.x * 0.92
		target_scale = target_width / grid_pixel_width
	else:
		# Querformat (Desktop)
		var target_height = visible_size.y * 0.70
		target_scale = target_height / grid_pixel_height

	scale = Vector2(target_scale, target_scale)

	var scaled_grid_width = grid_pixel_width * target_scale
	
	# Spielfeld zentrieren
	position.x = (visible_size.x - scaled_grid_width) / 2.0
	position.y = 120.0 * target_scale
	
	game_board.board_offset = Vector2.ZERO
	
	if $GridDrawer:
		$GridDrawer.setup(game_board.board_offset, COLUMNS, ROWS, TILE_SIZE)

	# --- NEU: Header an das Board anpassen ---
	if ui_manager and ui_manager.has_method("adjust_header"):
		ui_manager.adjust_header(position.x, position.y, scaled_grid_width, target_scale)


func generate_next_colors(count: int):
	next_colors.clear()
	for i in range(count):
		next_colors.append(COLORS[randi() % COLORS.size()])


# --- Spawning & Input ---

func spawn_random_balls(count: int):
	var empty_cells: Array[Vector2i] = game_board.get_empty_cells()
	empty_cells.shuffle()
	
	var spawn_count = min(count, empty_cells.size())
	
	for i in range(spawn_count):
		var cell = empty_cells[i]
		var ball_color = next_colors[i] if i < next_colors.size() else COLORS[randi() % COLORS.size()]
		spawn_ball_at(cell.x, cell.y, ball_color)

	generate_next_colors(3)
	ui_manager.update_preview(next_colors, ball_scene)


func trigger_game_over():
	is_game_over = true

	# Prüfen, ob der Score gut genug für die Liste ist
	var qualifies_for_leaderboard = leaderboard_manager.is_high_score(score)

	# UI-Manager informieren und Daten übergeben
	ui_manager.show_game_over(score, qualifies_for_leaderboard, leaderboard_manager.leaderboard_data)


func _on_restart_button_pressed():
	get_tree().reload_current_scene()


func spawn_ball_at(x: int, y: int, color: Color):
	var ball = ball_scene.instantiate()
	ball.grid_position = Vector2i(x, y)
	ball.position = game_board.grid_to_pixel(Vector2i(x, y))
	ball.set_color(color)
	add_child(ball)
	game_board.grid[x][y] = ball


func _input(event):
	if is_game_over:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos = game_board.pixel_to_grid(get_local_mouse_position())

		if grid_pos != Vector2i(-1, -1):
			handle_click(grid_pos.x, grid_pos.y)


func handle_click(grid_x: int, grid_y: int):
	# Konsequent game_board.grid nutzen!
	var clicked_ball = game_board.grid[grid_x][grid_y]

	if clicked_ball == null:
		if selected_ball != null:
			var start = Vector2i(selected_ball.grid_position)
			var target = Vector2i(grid_x, grid_y)
			
			var path = GridPathfinder.find_path(start, target, game_board.grid, COLUMNS, ROWS)
			if path.size() > 0:
				move_ball_along_path(selected_ball, path)
		return

	if selected_ball == clicked_ball:
		deselect_ball()
	else:
		select_ball(clicked_ball)


# --- Selection & Animation ---

func select_ball(ball: Ball):
	if selected_ball != null:
		deselect_ball()
	selected_ball = ball
	create_tween().tween_property(selected_ball, "scale", Vector2(0.9, 0.9), 0.15).set_trans(Tween.TRANS_BACK)


func deselect_ball():
	if selected_ball != null:
		create_tween().tween_property(selected_ball, "scale", Vector2(1.0, 1.0), 0.1)
		selected_ball = null


func move_ball_along_path(ball: Ball, path: Array[Vector2i]):
	game_board.grid[ball.grid_position.x][ball.grid_position.y] = null
	deselect_ball()

	var target_grid_pos = path[-1]
	ball.grid_position = target_grid_pos
	game_board.grid[target_grid_pos.x][target_grid_pos.y] = ball

	var tween = create_tween()
	for next_step in path:
		tween.tween_property(ball, "position", game_board.grid_to_pixel(next_step), 0.08).set_trans(Tween.TRANS_LINEAR)

	await tween.finished

	# 1. Prüfen, ob der eigene Zug Matches erzeugt hat
	var matched_balls = MatchChecker.find_matching_balls(game_board.grid, COLUMNS, ROWS)
	
	if matched_balls.size() > 0:
		await remove_matched_balls(matched_balls) # WICHTIG: await voranstellen!
	else:
		# 2. Keine Matches: Neue Bälle spawnen
		spawn_random_balls(3)
		
		# 3. Prüfen, ob durch das Spawnen Matches entstanden sind
		var chain_matches = MatchChecker.find_matching_balls(game_board.grid, COLUMNS, ROWS)
		if chain_matches.size() > 0:
			await remove_matched_balls(chain_matches) # WICHTIG: Bälle erst abräumen!

	# 4. JETZT erst prüfen, ob das Spielfeld nach allen Aktionen wirklich voll ist!
	check_game_over_conditions()


func check_game_over_conditions():
	if game_board.get_empty_cells().size() == 0:
		trigger_game_over()


func remove_matched_balls(balls: Array[Ball]):
	var points = 10 + (balls.size() - 5) * 5
	score += points
	
	ui_manager.update_score(score)

	var tween = create_tween().set_parallel(true)
	
	for ball in balls:
		game_board.grid[ball.grid_position.x][ball.grid_position.y] = null
		tween.tween_property(ball, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await tween.finished
	
	for ball in balls:
		ball.queue_free()
