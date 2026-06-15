extends Area2D

@export var speed: float = 300.0
@export var rotation_speed: float = 2.0
var direction: Vector2 = Vector2.ZERO

var velocity: Vector2 = Vector2.ZERO
var _planets_list: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_planets_list = get_tree().get_nodes_in_group("planets")

func _physics_process(delta: float) -> void:
	if velocity == Vector2.ZERO and direction != Vector2.ZERO:
		velocity = direction * speed

	if velocity != Vector2.ZERO:
		# Apply planet gravity pull
		for p in _planets_list:
			if not is_instance_valid(p):
				continue
			var p_diff = p.global_position - global_position
			var dist = p_diff.length()
			var grav_radius = 500.0
			var grav_shape = p.get_node_or_null("GravityArea/CollisionShape2D")
			if grav_shape and grav_shape.shape is CircleShape2D:
				grav_radius = grav_shape.shape.radius * p.scale.x
			
			if dist < grav_radius:
				var g_dir = p_diff.normalized()
				var planet_gravity = 600.0
				if "gravity_area" in p and p.gravity_area:
					planet_gravity = p.gravity_area.gravity
				# Pull the asteroid with 50% gravity strength for smooth deflection curves
				velocity += g_dir * planet_gravity * 0.5 * delta
		
		position += velocity * delta
		rotation += rotation_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player2D:
		var explosion_scene = ResourceManager.get_scene("res://scenes/explosion.tscn")
		if not explosion_scene: return
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().root.call_deferred("add_child", explosion)
		SoundManager.play_sfx("explosion")
		
		# Take 35% package damage instead of instant death
		GameManager.take_damage(35.0, "an asteroid destroyed your delivery box!")
		
		# Shake camera strongly
		var ui = get_tree().get_first_node_in_group("in_game_ui")
		if ui:
			ui.shake_camera(25.0, 0.45)
		
		# Knock back the player into space
		if not body.is_game_over:
			var push_dir = (body.global_position - global_position).normalized() if body.global_position != global_position else Vector2.UP
			body.velocity = push_dir * 500.0
			body.current_planet = null
			body._tether_planet = null
			body._tether_time_left = 0.0
			
		queue_free()
		
	# Asteroid destroys itself and explodes if it hits a planet
	elif body.name.begins_with("Planet"):
		var explosion = load("res://scenes/explosion.tscn").instantiate()
		explosion.global_position = global_position
		get_tree().root.call_deferred("add_child", explosion)
		SoundManager.play_sfx("explosion")
		
		# Shake camera slightly if player is near
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dist = player.global_position.distance_to(global_position)
			if dist < 800.0:
				var ui = get_tree().get_first_node_in_group("in_game_ui")
				if ui:
					var intensity = clamp(15.0 * (1.0 - dist / 800.0), 0.0, 15.0)
					ui.shake_camera(intensity, 0.3)
					
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
