# scripts/grid_drawer.gd
class_name GridDrawer
extends Node2D

var board_offset: Vector2 = Vector2.ZERO
var columns: int = 10
var rows: int = 10
var tile_size: int = 50

func setup(offset: Vector2, cols: int, rws: int, size: int):
	board_offset = offset
	columns = cols
	rows = rws
	tile_size = size
	queue_redraw()

func _draw():
	var grid_width = columns * tile_size
	var grid_height = rows * tile_size

	# 1. Hintergrund
	draw_rect(Rect2(board_offset, Vector2(grid_width, grid_height)), Color(0.622, 0.622, 0.622, 1.0))

	# 2. Vertikale & Horizontale Linien
	for x in range(columns + 1):
		var x_pos = board_offset.x + x * tile_size
		draw_line(Vector2(x_pos, board_offset.y), Vector2(x_pos, board_offset.y + grid_height), Color.BLACK, 1.5)

	for y in range(rows + 1):
		var y_pos = board_offset.y + y * tile_size
		draw_line(Vector2(board_offset.x, y_pos), Vector2(board_offset.x + grid_width, y_pos), Color.BLACK, 1.5)

	# 3. Rahmen
	draw_rect(Rect2(board_offset, Vector2(grid_width, grid_height)), Color.BLACK, false, 2.5)
