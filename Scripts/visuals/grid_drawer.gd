# scripts/visuals/grid_drawer.gd
class_name GridDrawer
extends Node2D

@export_group("Grid Colors")
@export var background_color: Color = Color(0.622, 0.622, 0.622, 1.0)
@export var line_color: Color = Color.BLACK
@export var border_color: Color = Color.BLACK

@export_group("Grid Settings")
@export var line_thickness: float = 1.5
@export var border_thickness: float = 2.5

var board_offset: Vector2 = Vector2.ZERO
var columns: int = 10
var rows: int = 10
var tile_size: int = 50


func setup(offset: Vector2, cols: int, rws: int, size: int) -> void:
	board_offset = offset
	columns = cols
	rows = rws
	tile_size = size
	queue_redraw()


func _draw() -> void:
	var grid_width = columns * tile_size
	var grid_height = rows * tile_size

	draw_rect(Rect2(board_offset, Vector2(grid_width, grid_height)), background_color)

	for x in range(1, columns):
		var x_pos = board_offset.x + x * tile_size
		draw_line(
			Vector2(x_pos, board_offset.y), 
			Vector2(x_pos, board_offset.y + grid_height), 
			line_color, 
			line_thickness, 
			true
		)

	for y in range(1, rows):
		var y_pos = board_offset.y + y * tile_size
		draw_line(
			Vector2(board_offset.x, y_pos), 
			Vector2(board_offset.x + grid_width, y_pos), 
			line_color, 
			line_thickness, 
			true
		)

	draw_rect(Rect2(board_offset, Vector2(grid_width, grid_height)), border_color, false, border_thickness)
