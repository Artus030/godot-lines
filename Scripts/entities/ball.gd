extends Area2D
class_name Ball

var color: Color = Color.WHITE
var grid_position: Vector2 = Vector2.ZERO
var selection_tween: Tween = null
var base_position: Vector2 = Vector2.ZERO

func _ready():
	$Sprite2D.modulate = color

func set_color(new_color: Color):
	color = new_color
	$Sprite2D.modulate = color
