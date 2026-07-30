extends Node2D

@export var ball_scene: PackedScene
@onready var ui_manager = $UILayer

const COLUMNS: int = 9
const ROWS: int = 9
const TILE_SIZE: int = 50
const SAVE_KEY: String = "latest_game_state"

var game_board: GameBoard
var spawner: SpawnerComponent

var score: int = 0
var is_game_over: bool = false
var selected_ball: Ball = null


func _ready():
	game_board = GameBoard.new(COLUMNS, ROWS, TILE_SIZE)
	spawner = SpawnerComponent.new()
	LeaderboardManager.load_leaderboard()
	
	ui_manager.restart_requested.connect(_on_restart_button_pressed)
	get_tree().root.size_changed.connect(calculate_center_offset)
	
	load_or_start_new_game()
	ui_manager.update_score(score)

	await get_tree().process_frame
	await get_tree().process_frame
	calculate_center_offset()


# --- Game Setup & State Management ---

func start_new_game():
	score = 0
	spawner.generate_next_colors(3)
	spawn_random_balls(5)
	save_current_game()

func save_current_game():
	var hex_next_colors: Array[String] = []
	for color in spawner.next_colors:
		hex_next_colors.append(color.to_html())
		
	var save_dictionary = {
		"score": score,
		"next_colors": hex_next_colors,
		"grid": game_board.get_grid_data_for_save()
	}
	
	PersistenceManager.save_data(SAVE_KEY, save_dictionary)

func load_or_start_new_game() -> void:
	var saved_state = PersistenceManager.load_data(SAVE_KEY, null)
	
	if saved_state != null and saved_state.has("grid"):
		var valid_grid_data = PersistenceManager.validate_board_data(saved_state["grid"], game_board.columns, game_board.rows)
		
		if valid_grid_data != null:
			score = saved_state.get("score", 0)
			ui_manager.update_score(score)
			
			spawner.next_colors = []
			for hex_color in saved_state.get("next_colors", []):
				spawner.next_colors.append(Color.html(hex_color))
			
			game_board.reset_grid()
			for ball_info in game_board.get_saved_balls_from_data(valid_grid_data["balls"]):
				spawn_ball_at(ball_info["grid_pos"].x, ball_info["grid_pos"].y, Color.html(ball_info["color"]))
				
			ui_manager.update_preview(spawner.next_colors, ball_scene)
			return

	PersistenceManager.erase_key(SAVE_KEY)
	start_new_game()


# --- Spawning & Input ---

func spawn_random_balls(count: int):
	var empty_cells = game_board.get_empty_cells()
	empty_cells.shuffle()
	
	var spawn_count = min(count, empty_cells.size())
	for i in range(spawn_count):
		var cell = empty_cells[i]
		spawn_ball_at(cell.x, cell.y, spawner.get_spawn_color_for_index(i))

	spawner.generate_next_colors(3)
	ui_manager.update_preview(spawner.next_colors, ball_scene)

func spawn_ball_at(x: int, y: int, color: Color):
	var ball = ball_scene.instantiate()
	ball.grid_position = Vector2i(x, y)
	ball.position = game_board.grid_to_pixel(Vector2i(x, y))
	ball.set_color(color)
	add_child(ball)
	game_board.grid[x][y] = ball


func _input(event):
	if is_game_over: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos = game_board.pixel_to_grid(get_local_mouse_position())
		if grid_pos != Vector2i(-1, -1):
			handle_click(grid_pos.x, grid_pos.y)

func handle_click(grid_x: int, grid_y: int):
	var clicked_ball = game_board.grid[grid_x][grid_y]
	if clicked_ball == null:
		if selected_ball != null:
			var path = GridPathfinder.find_path(selected_ball.grid_position, Vector2i(grid_x, grid_y), game_board.grid, COLUMNS, ROWS)
			if path.size() > 0:
				move_ball_along_path(selected_ball, path)
		return

	if selected_ball == clicked_ball:
		deselect_ball()
	else:
		select_ball(clicked_ball)


# --- Selection & Gameplay Loop ---

func select_ball(ball: Ball):
	deselect_ball()
	selected_ball = ball
	BoardAnimator.animate_selection(selected_ball)

func deselect_ball():
	if selected_ball != null:
		BoardAnimator.animate_deselection(selected_ball)
		selected_ball = null

func move_ball_along_path(ball: Ball, path: Array[Vector2i]):
	if ball.selection_tween and ball.selection_tween.is_running():
		ball.selection_tween.kill()
		ball.selection_tween = null

	game_board.grid[ball.grid_position.x][ball.grid_position.y] = null
	var target_grid_pos = path[-1]
	ball.grid_position = target_grid_pos
	game_board.grid[target_grid_pos.x][target_grid_pos.y] = ball

	await BoardAnimator.animate_path_movement(ball, path, game_board)
	
	ball.base_position = ball.position
	ball.scale = Vector2(1.0, 1.0)
	
	selected_ball = null

	var matched_balls = MatchChecker.find_matching_balls(game_board.grid, COLUMNS, ROWS)
	if matched_balls.size() > 0:
		await remove_matched_balls(matched_balls)
	else:
		spawn_random_balls(3)
		var chain_matches = MatchChecker.find_matching_balls(game_board.grid, COLUMNS, ROWS)
		if chain_matches.size() > 0:
			await remove_matched_balls(chain_matches)

	if game_board.get_empty_cells().size() == 0:
		trigger_game_over()
	else:
		save_current_game()

func remove_matched_balls(balls: Array[Ball]):
	score += 10 + (balls.size() - 5) * 5
	ui_manager.update_score(score)

	for ball in balls:
		game_board.grid[ball.grid_position.x][ball.grid_position.y] = null

	await BoardAnimator.animate_removal(balls)
	for ball in balls:
		ball.queue_free()

func trigger_game_over():
	is_game_over = true
	PersistenceManager.erase_key(SAVE_KEY)
	var qualifies = LeaderboardManager.is_high_score(score)
	ui_manager.show_game_over(score, qualifies, LeaderboardManager.leaderboard_data)

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func calculate_center_offset():
	var visible_size = get_viewport().get_visible_rect().size
	var grid_pixel_width = COLUMNS * TILE_SIZE
	var grid_pixel_height = ROWS * TILE_SIZE
	var target_scale = (visible_size.x * 0.92 / grid_pixel_width) if visible_size.x < visible_size.y else (visible_size.y * 0.70 / grid_pixel_height)

	scale = Vector2(target_scale, target_scale)
	var scaled_grid_width = grid_pixel_width * target_scale
	position.x = (visible_size.x - scaled_grid_width) / 2.0
	position.y = 120.0 * target_scale
	game_board.board_offset = Vector2.ZERO

	if $GridDrawer:
		$GridDrawer.setup(game_board.board_offset, COLUMNS, ROWS, TILE_SIZE)
	if ui_manager and ui_manager.has_method("adjust_header"):
		ui_manager.adjust_header(position.x, position.y, scaled_grid_width, target_scale)
