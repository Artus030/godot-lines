class_name BoardAnimator
static var particle_scene = preload("res://Scenes/ExplosionEffect.tscn")
static func animate_selection(ball: Ball) -> void:
	if ball == null:
		return
		
	# Laufende Schleifen-Tweens stoppen
	if ball.selection_tween and ball.selection_tween.is_running():
		ball.selection_tween.kill()
	
	ball.base_position = ball.position
	
	# Tween mit unendlicher Schleife erstellen
	ball.selection_tween = ball.create_tween().set_loops()
	
	# 1. Hochspringen (5px) + leicht strecken & verkleinern
	ball.selection_tween.tween_property(ball, "position:y", ball.base_position.y - 5.0, 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ball.selection_tween.parallel().tween_property(ball, "scale", Vector2(0.75, 0.77), 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# 2. Aufprall unten: Leicht stauchen (breiter & flacher)
	ball.selection_tween.chain().tween_property(ball, "position:y", ball.base_position.y, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	ball.selection_tween.parallel().tween_property(ball, "scale", Vector2(0.85, 0.75), 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


static func animate_deselection(ball: Ball) -> void:
	if ball == null:
		return
		
	if ball.selection_tween and ball.selection_tween.is_running():
		ball.selection_tween.kill()
		ball.selection_tween = null
	
	# Immer zur Ursprungsposition und Originalgröße zurückkehren
	var reset_tween = ball.create_tween().set_parallel(true)
	reset_tween.tween_property(ball, "position", ball.base_position, 0.1)
	reset_tween.tween_property(ball, "scale", Vector2(1.0, 1.0), 0.1)


static func animate_path_movement(ball: Ball, path: Array[Vector2i], board: GameBoard) -> Signal:
	var tween = ball.create_tween()
	for next_step in path:
		tween.tween_property(ball, "position", board.grid_to_pixel(next_step), 0.08).set_trans(Tween.TRANS_LINEAR)
	return tween.finished


static func animate_removal(balls: Array[Ball]) -> void:
	if balls.is_empty():
		return
		
	for ball in balls:
		# --- Partikel erzeugen (CPUParticles2D für den Browser) ---
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
		

	await balls[0].get_tree().create_timer(0.18).timeout
