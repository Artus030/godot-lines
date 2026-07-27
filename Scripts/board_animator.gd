class_name BoardAnimator

static func animate_selection(ball: Ball) -> Tween:
	var tween = ball.create_tween()
	tween.tween_property(ball, "scale", Vector2(0.9, 0.9), 0.15).set_trans(Tween.TRANS_BACK)
	return tween

static func animate_deselection(ball: Ball) -> Tween:
	var tween = ball.create_tween()
	tween.tween_property(ball, "scale", Vector2(1.0, 1.0), 0.1)
	return tween

static func animate_path_movement(ball: Ball, path: Array[Vector2i], board: GameBoard) -> Signal:
	var tween = ball.create_tween()
	for next_step in path:
		tween.tween_property(ball, "position", board.grid_to_pixel(next_step), 0.08).set_trans(Tween.TRANS_LINEAR)
	return tween.finished

static func animate_removal(balls: Array[Ball]) -> void:
	if balls.is_empty():
		return
	var tween = balls[0].create_tween().set_parallel(true)
	for ball in balls:
		tween.tween_property(ball, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
