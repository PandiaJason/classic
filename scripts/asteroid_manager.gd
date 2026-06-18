extends Node

var asteroid_scene = preload("res://scenes/asteroid.tscn")
var spawn_timer: Timer

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	_update_timer_for_level()

func _update_timer_for_level():
	# Faster spawning at higher levels
	# Level 4: 3.5s, Level 10: 2.5s, Level 20: 1.5s, Level 30: 1.0s
	var level = GameManager.current_level
	var base_interval = clamp(4.0 - (level * 0.1), 1.0, 3.5)
	spawn_timer.wait_time = base_interval

func _on_spawn_timer_timeout() -> void:
	# Do not spawn in menus
	var scene = get_tree().current_scene
	if not is_instance_valid(scene) or scene.name in ["Menu", "LevelSelect", "SplashScreen"]:
		return
		
	# Do not spawn before gameplay starts (countdown/zoom-in phase)
	if not GameManager.is_gameplay_started:
		return
		
	# Only spawn in Level 4 and above
	if GameManager.current_level < 4:
		return
	
	_update_timer_for_level()
		
	# Find the player to know where to spawn relative to them
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	
	# Spawn chance increases with level
	# Level 4-5: 30%, Level 10: 50%, Level 20: 75%, Level 30: 90%
	var level = GameManager.current_level
	var spawn_chance = clamp(0.2 + (level * 0.025), 0.3, 0.9)
	if randf() > spawn_chance:
		return
	
	# Number of asteroids per spawn increases with level
	# Level 4-9: 1, Level 10-19: 1-2, Level 20-29: 1-3, Level 30: 2-3
	var max_count = 1
	if level >= 10:
		max_count = 2
	if level >= 20:
		max_count = 3
	
	var count = randi_range(1, max_count)
	for i in count:
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
	
	# Speed increases with level — harder to dodge
	var level = GameManager.current_level
	var min_speed = clamp(150.0 + (level * 5.0), 150.0, 350.0)
	var max_speed = clamp(400.0 + (level * 8.0), 400.0, 650.0)
	asteroid.speed = randf_range(min_speed, max_speed)
	asteroid.rotation_speed = randf_range(-5.0, 5.0)
	
	# Add to current scene
	var scene = get_tree().current_scene
	if is_instance_valid(scene):
		scene.add_child(asteroid)
	else:
		asteroid.queue_free()
