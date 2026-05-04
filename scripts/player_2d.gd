extends CharacterBody2D
class_name Player2D

@export var max_speed = 250.0
@export var brake_force = 300.0
@export var jump_force = -500.0
@export var gravity_strength = 600.0
@export var is_menu_demo: bool = false

@onready var sprite = $Visuals/Sprite2D

var current_planet: Node2D = null
var last_planet: Node2D = null
var current_speed: float = 400.0
var forward_direction: float = 1.0 # 1 for clockwise, -1 for counter-clockwise
var is_game_over: bool = false
var has_jumped: bool = false
var show_trajectory: bool = false
var overlapping_gravity_areas: Array = []
var was_on_ground: bool = true

var trajectory_points: Array[Vector2] = []
@onready var floor_ray = $RayCast2D

func _ready() -> void:
	add_to_group("player")
	current_speed = max_speed
	
	# Setup an Area2D to detect gravity fields (Spatial Partitioning O(log N) instead of O(N) array search)
	var detector = Area2D.new()
	detector.name = "GravityDetector"
	detector.collision_layer = 0
	detector.collision_mask = 4 # Match planet's GravityArea collision layer
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10.0 # Small detector point
	shape.shape = circle
	detector.add_child(shape)
	add_child(detector)
	
	detector.area_entered.connect(_on_gravity_area_entered)
	detector.area_exited.connect(_on_gravity_area_exited)
	
	# Pre-fetch planets list once to avoid repeated scene tree lookups
	_planets_list = get_tree().get_nodes_in_group("planets")

var _planets_list: Array = []

func _on_gravity_area_entered(area: Area2D) -> void:
	if area.name == "GravityArea" and not overlapping_gravity_areas.has(area):
		overlapping_gravity_areas.append(area)

func _on_gravity_area_exited(area: Area2D) -> void:
	if overlapping_gravity_areas.has(area):
		overlapping_gravity_areas.erase(area)

func _input(event: InputEvent) -> void:
	if not is_menu_demo and event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _physics_process(delta: float) -> void:
	if is_game_over:
		return
		
	# Determine if on ground BEFORE finding gravity source to prevent accidental planet swapping
	var on_ground = false
	if current_planet:
		var diff = current_planet.global_position - global_position
		var surface_up = -diff.normalized()
		var dist_to_planet = diff.length()
		var surface_radius = 100.0 * current_planet.scale.x
		var is_near_surface = dist_to_planet <= surface_radius + 5.0
		var vertical_speed = velocity.dot(surface_up)
		on_ground = is_on_floor() or (is_near_surface and vertical_speed <= 10.0)
		
	# 1. Find the nearest valid gravity source
	find_gravity_source(on_ground)
	
	if current_planet:
		# 2. Calculate gravity direction
		var diff = current_planet.global_position - global_position
		var gravity_dir = diff.normalized()
		var surface_up = -gravity_dir
		
		# 3. Rotate player to align with gravity
		var target_rotation = gravity_dir.angle() - PI/2
		rotation = lerp_angle(rotation, target_rotation, 25 * delta)
		
		var surface_right = Vector2.RIGHT.rotated(target_rotation)
		
		# Carry momentum direction when entering a new gravity field
		if current_planet != last_planet:
			if velocity.dot(surface_right) < 0:
				forward_direction = -1.0
			else:
				forward_direction = 1.0
				
			# Inherit physical properties from the new planet
			if "planet_speed" in current_planet:
				max_speed = current_planet.planet_speed
			if "planet_jump_force" in current_planet:
				jump_force = current_planet.planet_jump_force
			if "gravity_area" in current_planet and current_planet.gravity_area:
				gravity_strength = current_planet.gravity_area.gravity
				
			# Guarantee capture: kill outward velocity and cap tangent velocity
			var outward_speed = velocity.dot(surface_up)
			if outward_speed > 0:
				velocity -= surface_up * outward_speed
				
			var tangent_speed = velocity.dot(surface_right)
			if abs(tangent_speed) > current_speed:
				velocity -= surface_right * (tangent_speed - (current_speed * sign(tangent_speed)))
				
		last_planet = current_planet
		
		# 4. Handle auto-drive and braking
		var direction = Input.get_axis("ui_left", "ui_right")
		
		if direction < 0:
			current_speed -= brake_force * delta
		else:
			current_speed += brake_force * 0.5 * delta
			
		current_speed = clamp(current_speed, 0.0, max_speed)
		
		# Re-evaluate on_ground just to be safe
		var dist_to_planet = diff.length()
		var surface_radius = 100.0 * current_planet.scale.x
		var is_near_surface = dist_to_planet <= surface_radius + 5.0
		var vertical_speed = velocity.dot(surface_up)
		on_ground = is_on_floor() or (is_near_surface and vertical_speed <= 10.0)
		
		if not is_menu_demo and on_ground and current_planet != null and "type" in current_planet:
			if current_planet.type == 3: # PlanetType.CHALLENGE
				is_game_over = true
				if GameManager.has_box:
					GameManager.level_complete()
				else:
					GameManager.game_over("You forgot the delivery box!")
				return
		
		# Check game over condition
		if not is_menu_demo and current_speed <= 0.0 and on_ground:
			is_game_over = true
			GameManager.game_over("Your bike stopped!")
			return

		# Handle off-screen death
		if not is_menu_demo and not is_game_over:
			var screen_pos = get_global_transform_with_canvas().origin
			var viewport_rect = get_viewport().get_visible_rect()
			# If off screen by more than 50px, game over
			if not viewport_rect.grow(50).has_point(screen_pos):
				is_game_over = true
				GameManager.game_over("You drifted away into deep space!")
				return
		
		# Create a falling-gravity well: gravity is much stronger when falling towards the planet
		# This guarantees we get captured by the planet instead of slingshotting past it,
		# while still allowing us to jump high when moving away from the planet.
		var applied_gravity = gravity_strength
		if not on_ground and velocity.dot(gravity_dir) > 0:
			applied_gravity = gravity_strength * 3.0
		
		# Always apply gravity to ensure we stay pushed against the floor
		velocity += gravity_dir * applied_gravity * delta
		
		if on_ground and not was_on_ground:
			# Player just landed on a planet
			if not is_menu_demo and has_jumped:
				has_jumped = false
				if current_planet != null and "type" in current_planet and current_planet.type != 3:
					GameManager.take_jump_damage()
		was_on_ground = on_ground

		# 5. Handle movement
		if on_ground:
			# We are on the ground. Replace horizontal velocity but keep the vertical gravity push!
			var current_vertical = velocity.dot(surface_up)
			# Clamp vertical velocity to prevent basketball bouncing
			if current_vertical > 0.0:
				current_vertical = 0.0
				
			velocity = (surface_right * current_speed * forward_direction) + (surface_up * current_vertical)
				
			if not is_menu_demo and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")):
				# Real Jump!
				print("JUMP!")
				has_jumped = true
				# Override the vertical velocity entirely to launch upwards
				velocity = (surface_right * current_speed * forward_direction) + (surface_up * -jump_force)
		else:
			# Add a tiny bit of air control / forward momentum
			velocity += surface_right * current_speed * forward_direction * delta * 0.5
			
		up_direction = surface_up
		floor_constant_speed = true
		
		# If we just jumped, we MUST disable snapping so we can leave the ground!
		if not is_menu_demo and has_jumped:
			floor_snap_length = 0.0
		else:
			floor_snap_length = 15.0 if on_ground else 0.0
			
		move_and_slide()
		
	else:
		# ZERO GRAVITY STATE
		# Player floats in a straight line with their current velocity
		last_planet = null
		move_and_slide()
		
		# Out of bounds check: if we leave the camera's visible area, we are lost
		if not is_menu_demo and not is_game_over:
			var cam = get_viewport().get_camera_2d()
			if cam:
				var screen_size = get_viewport_rect().size / cam.zoom
				var cam_pos = cam.global_position
				# Allow a 300px buffer outside the screen before killing them
				var min_x = cam_pos.x - (screen_size.x / 2.0) - 100
				var max_x = cam_pos.x + (screen_size.x / 2.0) + 100
				var min_y = cam_pos.y - (screen_size.y / 2.0) - 100
				var max_y = cam_pos.y + (screen_size.y / 2.0) + 100
				
				if global_position.x < min_x or global_position.x > max_x or global_position.y < min_y or global_position.y > max_y:
					is_game_over = true
					GameManager.game_over("You drifted into deep space!")
					return
			
	if show_trajectory and not is_menu_demo and current_planet != null and on_ground:
		calculate_trajectory()
	else:
		trajectory_points.clear()
			
	update_sprite_region()
	queue_redraw()

func _draw():
	if show_trajectory and trajectory_points.size() > 0:
		for p in trajectory_points:
			# p is in global coordinates, so we need to convert to local to draw properly
			draw_circle(to_local(p), 4.0, Color(1.0, 1.0, 1.0, 0.7))

func update_sprite_region():
	# Flip sprite based on forward direction
	sprite.flip_h = forward_direction < 0

func find_gravity_source(on_ground: bool) -> void:
	# Core Logic: If we are safely on the ground, do not allow another planet's gravity to snatch us!
	if current_planet != null and on_ground:
		return
		
	var closest_dist: float = INF
	var closest: Node2D = null
	
	for area in overlapping_gravity_areas:
		if is_instance_valid(area) and area.get_parent() is Node2D:
			var planet = area.get_parent()
			var surface_radius = 100.0 * planet.scale.x
			var dist = global_position.distance_to(planet.global_position) - surface_radius
			if dist < closest_dist:
				closest_dist = dist
				closest = planet
	
	current_planet = closest

func calculate_trajectory():
	trajectory_points.clear()
	
	var sim_pos = global_position
	var diff = current_planet.global_position - global_position
	var gravity_dir = diff.normalized()
	var surface_up = -gravity_dir
	
	# Use the actual current rotation for accurate surface_right
	var target_rotation = gravity_dir.angle() - PI/2
	var surface_right = Vector2.RIGHT.rotated(target_rotation)
	
	# Simulate a jump: tangential speed + upward launch
	var sim_vel = (surface_right * current_speed * forward_direction) + (surface_up * -jump_force)
	
	var sim_delta = 0.05
	trajectory_points.append(sim_pos)
	
	for i in range(120): # Simulate 6 seconds
		var nearest_planet = null
		var nearest_surface_dist = INF
		
		for p in _planets_list:
			var dist_to_center = sim_pos.distance_to(p.global_position)
			
			# Check if we are within this planet's gravity field
			var grav_radius = 500.0
			var grav_shape = p.get_node_or_null("GravityArea/CollisionShape2D")
			if grav_shape and grav_shape.shape is CircleShape2D:
				grav_radius = grav_shape.shape.radius * p.scale.x
			
			if dist_to_center < grav_radius:
				var surface_radius = 100.0 * p.scale.x
				var surface_dist = dist_to_center - surface_radius
				if surface_dist < nearest_surface_dist:
					nearest_surface_dist = surface_dist
					nearest_planet = p
		
		if nearest_planet:
			var p_diff = nearest_planet.global_position - sim_pos
			var g_dir = p_diff.normalized()
			var sim_gravity = gravity_strength
			if "gravity_area" in nearest_planet and nearest_planet.gravity_area:
				sim_gravity = nearest_planet.gravity_area.gravity
			# Apply stronger gravity when falling toward planet (matches physics_process)
			var multiplier = 3.0 if sim_vel.dot(g_dir) > 0 else 1.0
			sim_vel += g_dir * sim_gravity * multiplier * sim_delta
		
		sim_pos += sim_vel * sim_delta
		
		# Stop if we hit a planet surface
		if nearest_planet:
			var surface_radius = 100.0 * nearest_planet.scale.x
			if sim_pos.distance_to(nearest_planet.global_position) <= surface_radius:
				trajectory_points.append(sim_pos)
				break
		
		trajectory_points.append(sim_pos)
