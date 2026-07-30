class_name MatchChecker

static func find_matching_balls(grid: Array[Array], cols: int, rows: int) -> Array[Ball]:
	var balls_to_remove: Dictionary = {} # Verhindert Duplikate bei Überschneidungen

	for x in range(cols - 4):
		for y in range(rows):
			var line = [grid[x][y], grid[x+1][y], grid[x+2][y], grid[x+3][y], grid[x+4][y]]
			if _all_same_color(line):
				for ball in line:
					balls_to_remove[ball] = true

	for x in range(cols):
		for y in range(rows - 4):
			var line = [grid[x][y], grid[x][y+1], grid[x][y+2], grid[x][y+3], grid[x][y+4]]
			if _all_same_color(line):
				for ball in line:
					balls_to_remove[ball] = true

	for x in range(cols - 4):
		for y in range(rows - 4):
			var line = [grid[x][y], grid[x+1][y+1], grid[x+2][y+2], grid[x+3][y+3], grid[x+4][y+4]]
			if _all_same_color(line):
				for ball in line:
					balls_to_remove[ball] = true

	for x in range(cols - 4):
		for y in range(4, rows):
			var line = [grid[x][y], grid[x+1][y-1], grid[x+2][y-2], grid[x+3][y-3], grid[x+4][y-4]]
			if _all_same_color(line):
				for ball in line:
					balls_to_remove[ball] = true

	var result: Array[Ball] = []
	for ball in balls_to_remove.keys():
		result.append(ball)
		
	return result

static func _all_same_color(balls: Array) -> bool:
	for b in balls:
		if b == null:
			return false
	var c = balls[0].color
	for b in balls:
		if b.color != c:
			return false
	return true
