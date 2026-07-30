class_name GridPathfinder

static func find_path(start: Vector2i, target: Vector2i, grid: Array[Array], cols: int, rows: int) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	var came_from: Dictionary = {}
	var directions = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	
	var path_found: bool = false
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if current == target:
			path_found = true
			break
			
		for dir in directions:
			var neighbor = current + dir
			if neighbor.x >= 0 and neighbor.x < cols and neighbor.y >= 0 and neighbor.y < rows:
				if not visited.has(neighbor) and grid[neighbor.x][neighbor.y] == null:
					visited[neighbor] = true
					came_from[neighbor] = current
					queue.append(neighbor)
	
	if not path_found:
		return []

	var path: Array[Vector2i] = []
	var curr = target
	while curr != start:
		path.append(curr)
		curr = came_from[curr]
	
	path.reverse()
	return path
