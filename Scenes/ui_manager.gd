# scripts/ui_manager.gd
class_name UIManager
extends CanvasLayer

@onready var score_label: Label = $TopLeftBox/ScoreLabel
@onready var preview_container: HBoxContainer = $TopMiddleBox/PreviewContainer
@onready var game_over_overlay: ColorRect = $GameOverOverlay
@onready var restart_button: Button = $GameOverOverlay/CenterContainer/VBoxContainer/RestartButton
@onready var game_over_panel = $GameOverPanel
@onready var name_input_field = $GameOverPanel/CenterContainer/VBoxContainer/NameLineEdit
@onready var save_score_button = $GameOverPanel/CenterContainer/VBoxContainer/SaveButton
@onready var leaderboard_grid = $GameOverPanel/CenterContainer/VBoxContainer/LeaderboardGrid

signal restart_requested

var current_score: int = 0
var main_leaderboard_ref: LeaderboardManager

func _ready() -> void:
	name_input_field.focus_entered.connect(_on_name_input_field_focus_entered)

func _on_name_input_field_focus_entered():
	# Sobald der Spieler auf das Feld tippt/klickt, Tastatur öffnen
	if OS.has_feature("web") or OS.has_feature("mobile"):
		DisplayServer.virtual_keyboard_show(name_input_field.text)

func update_score(score: int):
	score_label.text = "Punkte: " + str(score)
	score_label.pivot_offset = score_label.size / 2.0
	
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

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

func show_game_over(score: int, is_highscore: bool, current_leaderboard: Array):
	current_score = score
	game_over_panel.show()
	
	# Zeige die Namenseingabe NUR, wenn es ein Highscore ist
	if is_highscore:
		name_input_field.show()
		save_score_button.show()
		name_input_field.grab_focus()
		if OS.has_feature("web") or OS.has_feature("mobile"):
			# Zwingt Godot im Web, die Tastatur aufzurufen
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
		# Dehnt die Namensspalte aus, damit Punkte ganz rechts stehen
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		leaderboard_grid.add_child(name_label)
		
		# 3. Spalte: Punkte
		var score_label = Label.new()
		score_label.text = "%d Pkt." % entry["score"]
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		leaderboard_grid.add_child(score_label)


# Das Signal vom "Speichern"-Button verbinden:
func _on_save_button_pressed():
	var player_name = name_input_field.text
	
	# Zugriff auf das Leaderboard über das Hauptskript
	var main_scene = get_parent() # Oder wie deine Hauptszene erreichbar ist
	main_scene.leaderboard_manager.add_entry(player_name, current_score)
	
	# UI aktualisieren
	if OS.has_feature("web") or OS.has_feature("mobile"):
		DisplayServer.virtual_keyboard_hide()
		name_input_field.release_focus()
	name_input_field.hide()
	save_score_button.hide()
	render_leaderboard(main_scene.leaderboard_manager.leaderboard_data)


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
