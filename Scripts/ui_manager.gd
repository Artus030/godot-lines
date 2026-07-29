# scripts/ui_manager.gd
class_name UIManager
extends CanvasLayer

@onready var score_label: Label = $HeaderContainer/HBoxContainer/ScoreLabel
@onready var preview_container: HBoxContainer = $HeaderContainer/HBoxContainer/PreviewContainer
@onready var game_over_overlay: ColorRect = $GameOverOverlay
@onready var restart_button: Button = $GameOverPanel/CenterContainer/VBoxContainer/RestartButton
@onready var game_over_panel = $GameOverPanel
@onready var name_input_field = $GameOverPanel/CenterContainer/VBoxContainer/NameLineEdit
@onready var save_score_button = $GameOverPanel/CenterContainer/VBoxContainer/SaveButton
@onready var leaderboard_grid = $GameOverPanel/CenterContainer/VBoxContainer/LeaderboardGrid
@onready var header_container = $"HeaderContainer"

signal restart_requested

var current_score: int = 0
var main_leaderboard_ref: LeaderboardManager


func _ready() -> void:
	name_input_field.focus_entered.connect(_on_name_input_field_focus_entered)
	
	# Falls der Save-Button noch nicht über den Godot-Editor verbunden ist:
	if not save_score_button.pressed.is_connected(_on_save_button_pressed):
		save_score_button.pressed.connect(_on_save_button_pressed)


func _on_name_input_field_focus_entered():
	if OS.has_feature("web") or OS.has_feature("mobile"):
		DisplayServer.virtual_keyboard_show(name_input_field.text)


func update_score(score: int):
	score_label.text = "Punkte: " + str(score)
	score_label.pivot_offset = score_label.size / 2.0
	
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)


func adjust_header(board_x: float, board_y: float, board_width: float, current_scale: float):
	if not header_container:
		return

	header_container.custom_minimum_size.x = board_width / current_scale
	header_container.scale = Vector2(current_scale, current_scale)
	header_container.position.x = board_x
	header_container.position.y = board_y - (55.0 * current_scale)


func update_preview(next_colors: Array[Color], ball_scene: PackedScene):
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
		ball.set_color(color)
		
		wrapper.add_child(ball)
		preview_container.add_child(wrapper)


# --- GAME OVER & LEADERBOARD LOGIK ---

func show_game_over(score: int, is_highscore: bool, current_leaderboard: Array):
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


func render_leaderboard(leaderboard_data: Array):
	# Alte Einträge im Grid löschen
	for child in leaderboard_grid.get_children():
		leaderboard_grid.remove_child(child)
		child.queue_free()

	# Falls die Daten noch laden / leer sind
	if leaderboard_data.size() == 0:
		var loading_label = Label.new()
		loading_label.text = "Lade Highscores..."
		leaderboard_grid.add_child(loading_label)
		return

	# Für jeden Eintrag 3 Spalten (Labels) anlegen
	for i in range(leaderboard_data.size()):
		var entry = leaderboard_data[i]
		
		# 1. Spalte: Rang
		var rank_label = Label.new()
		rank_label.text = "%d." % (i + 1)
		leaderboard_grid.add_child(rank_label)
		
		# 2. Spalte: Name
		var name_label = Label.new()
		name_label.text = entry["name"]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		leaderboard_grid.add_child(name_label)
		
		# 3. Spalte: Punkte
		var score_label = Label.new()
		score_label.text = "%d Pkt." % entry["score"]
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		leaderboard_grid.add_child(score_label)


func _on_save_button_pressed():
	var player_name = name_input_field.text
	var main_scene = get_parent()
	var leaderboard = main_scene.leaderboard_manager
	
	# UI kurz "sperren" während gesendet wird
	save_score_button.disabled = true
	
	# Tastatur schließen & Eingabefeld verstecken
	if OS.has_feature("web") or OS.has_feature("mobile"):
		DisplayServer.virtual_keyboard_hide()
		name_input_field.release_focus()
	name_input_field.hide()
	save_score_button.hide()
	
	# Ladeanzeige im Grid schalten
	render_leaderboard([])
	
	# Einmalige Verbindung herstellen, wenn die Daten von Supabase zurück sind:
	if not leaderboard.leaderboard_loaded.is_connected(_on_leaderboard_updated_after_save):
		leaderboard.leaderboard_loaded.connect(_on_leaderboard_updated_after_save, CONNECT_ONE_SHOT)
	
	# An Supabase senden (lädt am Ende automatisch die neue Liste!)
	leaderboard.add_entry(player_name, current_score)


func _on_leaderboard_updated_after_save(new_data: Array):
	render_leaderboard(new_data)


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
