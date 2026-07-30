class_name BoardAnimator
extends RefCounted

static var particle_scene: PackedScene = preload("res://Scenes/ExplosionEffect.tscn")


static func animate_selection(ball: Ball) -> void:
	if not is_instance_valid(ball):
		return
		
	if not (ball.selection_tween and ball.selection_tween.is_valid() and ball.selection_tween.is_running()):
		ball.base_position = ball.position
		
	if ball.selection_tween and ball.selection_tween.is_valid():
		ball.selection_tween.kill()
	
	ball.selection_tween = ball.create_tween().set_loops()
	
	ball.selection_tween.tween_property(ball, "position:y", ball.base_position.y - 5.0, 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ball.selection_tween.parallel().tween_property(ball, "scale", Vector2(0.75, 0.77), 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	ball.selection_tween.chain().tween_property(ball, "position:y", ball.base_position.y, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	ball.selection_tween.parallel().tween_property(ball, "scale", Vector2(0.85, 0.75), 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


static func animate_deselection(ball: Ball) -> void:
	if not is_instance_valid(ball):
		return
		
	if ball.selection_tween and ball.selection_tween.is_valid():
		ball.selection_tween.kill()
		ball.selection_tween = null
	
	var reset_tween = ball.create_tween().set_parallel(true)
	reset_tween.tween_property(ball, "position", ball.base_position, 0.1)
	reset_tween.tween_property(ball, "scale", Vector2.ONE, 0.1)


static func animate_path_movement(ball: Ball, path: Array[Vector2i], board: GameBoard) -> void:
	if not is_instance_valid(ball) or path.is_empty():
		return
		
	var tween = ball.create_tween()
	for next_step in path:
		tween.tween_property(ball, "position", board.grid_to_pixel(next_step), 0.08).set_trans(Tween.TRANS_LINEAR)
		
	await tween.finished


static func animate_removal(balls: Array[Ball]) -> void:
	if balls.is_empty():
		return
		
	for ball in balls:
		if not is_instance_valid(ball):
			continue
			
		if particle_scene:
			var particles = particle_scene.instantiate() as CPUParticles2D
			if particles:
				particles.position = ball.position
				particles.modulate = ball.color
				ball.get_parent().add_child(particles)
		
		var pop_tween = ball.create_tween()
		pop_tween.tween_property(ball, "scale", Vector2(1.2, 1.2), 0.06)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
		pop_tween.chain().tween_property(ball, "scale", Vector2.ZERO, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		pop_tween.parallel().tween_property(ball, "modulate:a", 0.0, 0.12)
	
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		await tree.create_timer(0.18).timeout
