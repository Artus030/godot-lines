class_name UIManager
extends CanvasLayer

signal restart_requested

@onready var score_label: Label = $HeaderContainer/HBoxContainer/ScoreLabel
@onready var preview_container: HBoxContainer = $HeaderContainer/HBoxContainer/PreviewContainer
@onready var game_over_panel: Control = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/CenterContainer/VBoxContainer/RestartButton
@onready var name_input_field: LineEdit = $GameOverPanel/CenterContainer/VBoxContainer/NameLineEdit
@onready var save_score_button: Button = $GameOverPanel/CenterContainer/VBoxContainer/SaveButton
@onready var leaderboard_grid: GridContainer = $GameOverPanel/CenterContainer/VBoxContainer/LeaderboardGrid
@onready var header_container: Control = $HeaderContainer

var current_score: int = 0

func _ready() -> void:
	name_input_field.focus_entered.connect(_on_name_input_field_focus_entered)
	
	if not save_score_button.pressed.is_connected(_on_save_button_pressed):
		save_score_button.pressed.connect(_on_save_button_pressed)
		
	if not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)
		
	if LeaderboardManager:
		LeaderboardManager.leaderboard_loaded.connect(render_leaderboard)


func _on_name_input_field_focus_entered() -> void:
	if OS.has_feature("web") or OS.has_feature("mobile"):
		DisplayServer.virtual_keyboard_show(name_input_field.text)


func update_score(score: int) -> void:
	score_label.text = "Punkte: %d" % score
	score_label.pivot_offset = score_label.size / 2.0
	
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.1)


func adjust_header(board_x: float, board_y: float, board_width: float, current_scale: float) -> void:
	if not header_container:
		return

	header_container.custom_minimum_size.x = board_width / current_scale
	header_container.scale = Vector2(current_scale, current_scale)
	header_container.position = Vector2(board_x, board_y - (55.0 * current_scale))


func update_preview(next_colors: Array[Color], ball_scene: PackedScene) -> void:
	for child in preview_container.get_children():
		preview_container.remove_child(child)
		child.queue_free()
	
	var label = Label.new()
	label.text = "Vorschau: "
	preview_container.add_child(label)
	
	for color in next_colors:
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(30, 30)
		
		var ball = ball_scene.instantiate()
		ball.scale = Vector2(0.5, 0.5)
		ball.position = Vector2(15, 15)
		if ball.has_method("set_color"):
			ball.set_color(color)
		
		wrapper.add_child(ball)
		preview_container.add_child(wrapper)


# --- GAME OVER & LEADERBOARD LOGIC ---

func show_game_over(score: int, is_highscore: bool, current_leaderboard: Array) -> void:
	current_score = score
	game_over_panel.show()
	save_score_button.disabled = false
	
	if is_highscore:
		name_input_field.show()
		save_score_button.show()
		name_input_field.grab_focus()
		if OS.has_feature("web") or OS.has_feature("mobile"):
			DisplayServer.virtual_keyboard_show(name_input_field.text)
	else:
		name_input_field.hide()
		save_score_button.hide()
		
	render_leaderboard(current_leaderboard)


func render_leaderboard(leaderboard_data: Array) -> void:
	for child in leaderboard_grid.get_children():
		child.queue_free()

	if leaderboard_data.is_empty():
		var loading_label = Label.new()
		loading_label.text = "Lade Highscores..."
		leaderboard_grid.add_child(loading_label)
		return

	for i in range(leaderboard_data.size()):
		var entry = leaderboard_data[i]
		if not entry is Dictionary:
			continue
			
		var rank_label = Label.new()
		rank_label.text = "%d." % (i + 1)
		leaderboard_grid.add_child(rank_label)
		
		var name_label = Label.new()
		name_label.text = str(entry.get("name", "Player"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		leaderboard_grid.add_child(name_label)
		
		var score_label_entry = Label.new()
		score_label_entry.text = "%d Pkt." % entry.get("score", 0)
		score_label_entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		leaderboard_grid.add_child(score_label_entry)


func _on_save_button_pressed() -> void:
	var player_name = name_input_field.text.strip_edges()
	if player_name.is_empty():
		player_name = "Spieler"

	save_score_button.disabled = true
	
	if OS.has_feature("web") or OS.has_feature("mobile"):
		DisplayServer.virtual_keyboard_hide()
		name_input_field.release_focus()
		
	name_input_field.hide()
	save_score_button.hide()
	
	render_leaderboard([])
	
	LeaderboardManager.add_entry(player_name, current_score)


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
