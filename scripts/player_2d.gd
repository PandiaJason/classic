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

# Glide assist (resets each flight — use one per zero-gravity segment)
var _glide_used_this_flight: bool = false
signal glide_used
var _tether_planet: Node2D = null
var _tether_time_left: float = 0.0
var thruster_particles: CPUParticles2D = null
var flight_trail_particles: CPUParticles2D = null
var headlight: PointLight2D = null
var engine_light: PointLight2D = null

# Cinematic death state
var _doomed: bool = false
var _doom_timer: float = 0.0
const DOOM_DELAY: float = 2.5

var _wants_to_jump: bool = false
var _wants_to_brake: bool = false

var trajectory_points: Array[Vector2] = []
@onready var floor_ray = $RayCast2D

func _ready() -> void:
	add_to_group("player")
	current_speed = max_speed
	
	# Initialize maneuvering gas thruster particles dynamically
	thruster_particles = CPUParticles2D.new()
	add_child(thruster_particles)
	thruster_particles.emitting = false
	thruster_particles.amount = 40
	thruster_particles.lifetime = 0.35
	thruster_particles.explosiveness = 0.0
	thruster_particles.randomness = 0.6
	thruster_particles.local_coords = false
	thruster_particles.direction = Vector2.LEFT
	thruster_particles.spread = 15.0
	thruster_particles.gravity = Vector2.ZERO
	thruster_particles.initial_velocity_min = 250.0
	thruster_particles.initial_velocity_max = 350.0
	thruster_particles.scale_amount_min = 3.0
	thruster_particles.scale_amount_max = 8.0
	
	var ramp = Gradient.new()
	ramp.set_color(0, Color(0.6, 0.8, 1.0, 0.8))
	ramp.set_color(1, Color(0.2, 0.4, 0.8, 0.0))
	thruster_particles.color_ramp = ramp
	
	# Initialize flight trail particles dynamically
	flight_trail_particles = CPUParticles2D.new()
	add_child(flight_trail_particles)
	flight_trail_particles.emitting = false
	flight_trail_particles.amount = 30
	flight_trail_particles.lifetime = 0.5
	flight_trail_particles.local_coords = false
	flight_trail_particles.spread = 20.0
	flight_trail_particles.gravity = Vector2.ZERO
	flight_trail_particles.initial_velocity_min = 10.0
	flight_trail_particles.initial_velocity_max = 30.0
	flight_trail_particles.scale_amount_min = 1.5
	flight_trail_particles.scale_amount_max = 4.0
	
	var trail_ramp = Gradient.new()
	trail_ramp.set_color(0, Color(0.8, 0.95, 1.0, 0.4)) # Pale blue-white
	trail_ramp.set_color(1, Color(0.5, 0.8, 1.0, 0.0))
	flight_trail_particles.color_ramp = trail_ramp
	
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
	
	# Initialize headlight
	headlight = PointLight2D.new()
	headlight.texture = ResourceManager.get_light_texture()
	headlight.texture_scale = 1.8
	headlight.color = Color(1.0, 0.95, 0.8) # Warm white headlight
	headlight.energy = 0.8
	headlight.position = Vector2(0, -30)
	add_child(headlight)

	# Initialize engine booster glow
	engine_light = PointLight2D.new()
	engine_light.texture = ResourceManager.get_light_texture()
	engine_light.texture_scale = 1.0
	engine_light.color = Color(0.3, 0.7, 1.0) # Light blue thruster flame glow
	engine_light.energy = 0.0 # Starts off
	engine_light.position = Vector2(0, -18)
	add_child(engine_light)

var _planets_list: Array = []

func _on_gravity_area_entered(area: Area2D) -> void:
	if area.name == "GravityArea" and not overlapping_gravity_areas.has(area):
		overlapping_gravity_areas.append(area)

func _on_gravity_area_exited(area: Area2D) -> void:
	if overlapping_gravity_areas.has(area):
		overlapping_gravity_areas.erase(area)



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
		# Clear any active grapple tether since we are inside gravity
		_tether_planet = null
		_tether_time_left = 0.0
		
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
		var is_braking = direction < 0 or _wants_to_brake
		
		if is_braking:
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
					GameManager.game_over("you forgot the delivery box!")
				return
		
		# Check game over condition
		if not is_menu_demo and current_speed <= 0.0 and on_ground:
			is_game_over = true
			GameManager.game_over("your bike stopped!")
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
			_glide_used_this_flight = false  # Reset glide for next flight
			SoundManager.play_sfx("landing")
			
			# Trigger subtle camera shake on landing
			if not is_menu_demo:
				var ui = get_tree().get_first_node_in_group("in_game_ui")
				if ui:
					ui.shake_camera(8.0, 0.2)
			
			if not is_menu_demo:
				if has_jumped:
					has_jumped = false
					if current_planet != null and "type" in current_planet and current_planet.type != 3:
						GameManager.take_jump_damage()
				# Auto-hide trajectory hint after landing (regardless of how flight ended)
				show_trajectory = false
		was_on_ground = on_ground

		# 5. Handle movement
		if on_ground:
			# We are on the ground. Replace horizontal velocity but keep the vertical gravity push!
			var current_vertical = velocity.dot(surface_up)
			# Clamp vertical velocity to prevent basketball bouncing
			if current_vertical > 0.0:
				current_vertical = 0.0
				
			velocity = (surface_right * current_speed * forward_direction) + (surface_up * current_vertical)
				
			var jump_pressed = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up") or _wants_to_jump
			if not is_menu_demo and jump_pressed:
				# Real Jump!
				has_jumped = true
				# Override the vertical velocity entirely to launch upwards
				velocity = (surface_right * current_speed * forward_direction) + (surface_up * -jump_force)
				SoundManager.play_sfx("jump")
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
		
		# Glide assist - pull toward nearest planet (can use multiple times per flight)
		if not is_menu_demo and SaveSystem.glide_count > 0:
			var just_pressed = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up") or _wants_to_jump
			if just_pressed:
				var nearest = _find_nearest_planet()
				if nearest:
					_tether_planet = nearest
					_glide_used_this_flight = true
					SaveSystem.use_glide()
					glide_used.emit()
					_doomed = false
					_doom_timer = 0.0
					SoundManager.start_sfx_loop("thruster")
					
					# Grace timer if triggered by mobile touch tap
					if _wants_to_jump:
						_tether_time_left = 1.5
					else:
						_tether_time_left = 0.0
		
		# Apply tether pull in zero gravity
		if _tether_planet != null and is_instance_valid(_tether_planet):
			var is_holding = Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up")
			var should_release = false
			
			if _tether_time_left > 0.0:
				_tether_time_left -= delta
				if _tether_time_left <= 0.0:
					should_release = true
			elif not is_holding:
				should_release = true
				
			if should_release:
				_tether_planet = null
				_tether_time_left = 0.0
				SoundManager.stop_sfx_loop("thruster")
				if thruster_particles != null:
					thruster_particles.emitting = false
			else:
				var pull_dir = (_tether_planet.global_position - global_position).normalized()
				var pull_accel = 1200.0
				velocity += pull_dir * pull_accel * delta
				
				# Enable gas jet plume and orient it away from the planet (action-reaction)
				if thruster_particles != null:
					thruster_particles.emitting = true
					thruster_particles.global_rotation = (global_position - _tether_planet.global_position).angle()
				
				# Slingshot speed cap (600.0) for more momentum
				if velocity.length() > 600.0:
					velocity = velocity.normalized() * 600.0
		else:
			_tether_planet = null
			_tether_time_left = 0.0
			SoundManager.stop_sfx_loop("thruster")
			if thruster_particles != null:
				thruster_particles.emitting = false
			
		move_and_slide()
		
		if not is_menu_demo and not is_game_over:
			# --- CINEMATIC DEATH: detect doomed trajectory ---
			if not _doomed and not is_heading_towards_any_planet():
				_doomed = true
				_doom_timer = 0.0
			
			if _doomed:
				_doom_timer += delta
				# Spin the scooter to sell the tumbling feeling
				rotation += delta * (_doom_timer * 3.0 + 2.0)
				if _doom_timer >= DOOM_DELAY:
					is_game_over = true
					GameManager.game_over("lost in space")
					return
		
			# --- EXISTING safety net: hard out-of-bounds fallback ---
			var buffer = 1500.0
			var min_x = INF
			var max_x = -INF
			var min_y = INF
			var max_y = -INF
			for p in _planets_list:
				if is_instance_valid(p):
					min_x = min(min_x, p.global_position.x)
					max_x = max(max_x, p.global_position.x)
					min_y = min(min_y, p.global_position.y)
					max_y = max(max_y, p.global_position.y)
			if global_position.x < min_x - buffer or global_position.x > max_x + buffer or global_position.y < min_y - buffer or global_position.y > max_y + buffer:
				is_game_over = true
				GameManager.game_over("you drifted into deep space!")
				return
			
	if show_trajectory and not is_menu_demo:
		if current_planet != null and on_ground:
			calculate_trajectory()
		else:
			show_trajectory = false
			trajectory_points.clear()
	else:
		trajectory_points.clear()
			
	# Defensive safety cleanup for maneuvering gas thruster loop/particles
	var is_zero_g = current_planet == null and not on_ground
	if not is_zero_g or _tether_planet == null or is_game_over:
		SoundManager.stop_sfx_loop("thruster")
		if thruster_particles != null:
			thruster_particles.emitting = false
			
	# Update flight trail particles
	if is_instance_valid(flight_trail_particles):
		if not is_menu_demo and current_planet == null and velocity.length() > 50.0 and not is_game_over:
			flight_trail_particles.emitting = true
			flight_trail_particles.direction = -velocity.normalized()
		else:
			flight_trail_particles.emitting = false

	# Update lights
	if is_instance_valid(engine_light):
		if not is_game_over and current_planet == null:
			if _tether_planet != null:
				engine_light.energy = 1.5
				engine_light.color = Color(0.3, 0.7, 1.0) # Light blue thruster
				engine_light.texture_scale = 1.5
			else:
				engine_light.energy = 0.8
				engine_light.color = Color(0.8, 0.4, 0.1) # Orange engine flame
				engine_light.texture_scale = 1.0
		else:
			engine_light.energy = 0.2 # Faint idle glow on planet
			engine_light.color = Color(0.8, 0.4, 0.1)
			engine_light.texture_scale = 0.6

	if is_instance_valid(headlight):
		if is_game_over:
			headlight.energy = 0.0
		else:
			headlight.energy = 0.8
			var look_dir = forward_direction
			headlight.position = Vector2(look_dir * 15.0, -30)

	update_sprite_region()
	queue_redraw()
	
	_wants_to_jump = false # clear the input queue at the end of the frame

func _draw():
	if show_trajectory and trajectory_points.size() > 0:
		for i in range(trajectory_points.size()):
			var p = trajectory_points[i]
			var alpha = 1.0 - (float(i) / trajectory_points.size()) * 0.6
			draw_circle(to_local(p), 6.0, Color(1.0, 0.9, 0.2, alpha))
			
	# Maneuvering thrusters are pure rocket thrust (no magical ropes drawn)
	pass

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
	# If we just re-entered gravity, cancel the doomed state
	if current_planet != null and _doomed:
		_doomed = false
		_doom_timer = 0.0

func is_heading_towards_any_planet() -> bool:
	if velocity.length_squared() < 1.0:
		return true # Too slow to judge — give benefit of the doubt
	var v_dir = velocity.normalized()
	var p_pos = global_position
	for p in _planets_list:
		if not is_instance_valid(p):
			continue
		var to_planet = p.global_position - p_pos
		# Only check planets in front of us
		if to_planet.dot(v_dir) <= 0:
			continue
		# Distance from planet center to straight-line trajectory
		var proj_len = to_planet.dot(v_dir)
		var closest_pt = p_pos + v_dir * proj_len
		var dist_to_line = p.global_position.distance_to(closest_pt)
		var grav_radius = 500.0
		var grav_shape = p.get_node_or_null("GravityArea/CollisionShape2D")
		if grav_shape and grav_shape.shape is CircleShape2D:
			grav_radius = grav_shape.shape.radius * p.scale.x
		# 100px generous buffer so we don't trigger too early on near-misses
		if dist_to_line < grav_radius + 100.0:
			return true
	return false

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

func _find_nearest_planet() -> Node2D:
	var nearest: Node2D = null
	var min_dist: float = INF
	for p in _planets_list:
		if is_instance_valid(p):
			var dist = global_position.distance_to(p.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = p
	return nearest
