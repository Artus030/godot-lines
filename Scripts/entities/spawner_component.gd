class_name SpawnerComponent

const COLORS: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN,
	Color.YELLOW, Color.PURPLE, Color.ORANGE,
	Color.CYAN
]

var next_colors: Array[Color] = []

func generate_next_colors(count: int = 3) -> Array[Color]:
	next_colors.clear()
	for i in range(count):
		next_colors.append(COLORS.pick_random())
	return next_colors

func get_spawn_color_for_index(index: int) -> Color:
	if index < next_colors.size():
		return next_colors[index]
	return COLORS.pick_random()
