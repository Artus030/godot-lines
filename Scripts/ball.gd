extends Area2D
class_name Ball

# Farbe der Kugel (wird vom GameBoard zugewiesen)
var color: Color = Color.WHITE
var grid_position: Vector2 = Vector2.ZERO  # Position im Grid (x, y)

func _ready():
	# Sprite2D die Farbe zuweisen
	$Sprite2D.modulate = color

func set_color(new_color: Color):
	color = new_color
	$Sprite2D.modulate = color
