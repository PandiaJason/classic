extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Add a floating animation
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -10.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 10.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player2D":
		GameManager.add_score(10)
		GameManager.repair_box(5.0)
		SoundManager.play_sfx("ruby")
		_spawn_sparkle_particles()
		
		# Optional: Add collection sound or effect here
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free)

func _spawn_sparkle_particles():
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 15
	particles.lifetime = 0.4
	particles.explosiveness = 0.9
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(1.0, 0.9, 0.2) # Gold
	
	var ramp = Gradient.new()
	ramp.set_color(0, Color(1.0, 0.9, 0.2, 1.0))
	ramp.set_color(1, Color(1.0, 0.9, 0.2, 0.0))
	particles.color_ramp = ramp
	
	get_tree().root.add_child(particles)
	
	var timer = get_tree().create_timer(particles.lifetime + 0.1)
	timer.timeout.connect(particles.queue_free)
