extends Node

var asteroid_scene = preload("res://scenes/asteroid.tscn")
var spawn_timer: Timer

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 3.0 # Check every 3 seconds
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func _on_spawn_timer_timeout() -> void:
	# Do not spawn in menus
	var scene = get_tree().current_scene
	if not is_instance_valid(scene) or scene.name in ["Menu", "LevelSelect", "SplashScreen"]:
		return
		
	# Only spawn in Level 4 and above
	if GameManager.current_level < 4:
		return
		
	# Find the player to know where to spawn relative to them
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
		
	# 50% chance to spawn an asteroid every 3 seconds
	if randf() > 0.5:
		return
		
	spawn_asteroid(player.global_position)

func spawn_asteroid(player_pos: Vector2) -> void:
	var asteroid = asteroid_scene.instantiate()
	
	# Calculate dynamic spawn distance to ensure it's always outside the camera view
	var spawn_distance = 2500.0
	var cam = get_viewport().get_camera_2d()
	if is_instance_valid(cam):
		var screen_size = get_viewport().get_visible_rect().size / cam.zoom
		spawn_distance = (screen_size.length() / 2.0) + 400.0 # Diagonal radius + buffer
	
	var angle = randf() * PI * 2
	var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * spawn_distance
	
	asteroid.global_position = spawn_pos
	
	# Aim roughly towards the player's general area
	var target_offset = Vector2(randf_range(-400, 400), randf_range(-400, 400))
	var target_pos = player_pos + target_offset
	
	asteroid.direction = (target_pos - spawn_pos).normalized()
	
	# Randomize speed and rotation
	asteroid.speed = randf_range(200.0, 500.0)
	asteroid.rotation_speed = randf_range(-5.0, 5.0)
	
	# Add to current scene
	var scene = get_tree().current_scene
	if is_instance_valid(scene):
		scene.add_child(asteroid)
	else:
		asteroid.queue_free()
