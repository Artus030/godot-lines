class_name GameBoard

var columns: int
var rows: int
var tile_size: int
var board_offset: Vector2
var grid: Array[Array] = []

func _init(cols: int, rws: int, size: int):
	columns = cols
	rows = rws
	tile_size = size
	reset_grid()

func reset_grid():
	grid.clear()
	for x in range(columns):
		grid.append([])
		for y in range(rows):
			grid[x].append(null)

func get_empty_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(columns):
		for y in range(rows):
			if grid[x][y] == null:
				cells.append(Vector2i(x, y))
	return cells

func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * tile_size + (tile_size / 2.0) + board_offset.x,
		grid_pos.y * tile_size + (tile_size / 2.0) + board_offset.y
	)

func pixel_to_grid(local_mouse_pos: Vector2) -> Vector2i:
	var relative_pos = local_mouse_pos - board_offset
	if relative_pos.x < 0 or relative_pos.y < 0:
		return Vector2i(-1, -1)
	
	var x = int(relative_pos.x / tile_size)
	var y = int(relative_pos.y / tile_size)
	
	if x >= 0 and x < columns and y >= 0 and y < rows:
		return Vector2i(x, y)
	return Vector2i(-1, -1)

func get_grid_data_for_save() -> Dictionary:
	return {
		"cols": columns,
		"rows": rows,
		"balls": get_grid_balls_array()
	}
	
func get_grid_balls_array() -> Array:
	var data: Array = []
	for x in range(columns):
		var column_data: Array = []
		for y in range(rows):
			var tile = grid[x][y]
			if tile == null:
				column_data.append(null)
			else:
				column_data.append({
					"color": tile.color.to_html() 
				})
		data.append(column_data)
	return data

func get_saved_balls_from_data(saved_grid: Array) -> Array[Dictionary]:
	var balls_to_spawn: Array[Dictionary] = []
	
	for x in range(saved_grid.size()):
		for y in range(saved_grid[x].size()):
			var cell_data = saved_grid[x][y]
			if cell_data != null:
				balls_to_spawn.append({
					"grid_pos": Vector2i(x, y),
					"color": cell_data["color"]
				})
				
	return balls_to_spawn
