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
var _was_showing_trajectory: bool = false

# Glide assist (resets each flight — use one per zero-gravity segment)
var _glide_used_this_flight: bool = false
signal glide_used
# Speed boost assist
signal speed_used
var is_speed_buff_active: bool = false
var _wants_to_speed: bool = false
var _shift_was_pressed: bool = false
var _tether_planet: Node2D = null
var _tether_time_left: float = 0.0
var thruster_particles: CPUParticles2D = null
var flight_trail_particles: CPUParticles2D = null

# Cinematic death state
var _doomed: bool = false
var _doom_timer: float = 0.0
const DOOM_DELAY: float = 2.5

var _wants_to_jump: bool = false

var trajectory_points: Array[Vector2] = []
@onready var floor_ray = $RayCast2D

var _joy_jump_pressed: bool = false
var _joy_jump_just_pressed: bool = false
var _joy_speed_pressed: bool = false
var _joy_speed_just_pressed: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_A:
			_joy_jump_pressed = event.pressed
			if event.pressed:
				_joy_jump_just_pressed = true
		elif event.button_index == JOY_BUTTON_X:
			_joy_speed_pressed = event.pressed
			if event.pressed:
				_joy_speed_just_pressed = true

func _ready() -> void:
	add_to_group("player")
	
	# Setup controller inputs dynamically
	if not InputMap.has_action("speed"):
		InputMap.add_action("speed")
	_ensure_key("speed", KEY_SHIFT)
	_ensure_joy_button("speed", JOY_BUTTON_X)
		
	# Setup explicit jump for joystick
	if not InputMap.has_action("jump"):
		InputMap.add_action("jump")
	_ensure_joy_button("jump", JOY_BUTTON_A)
	_ensure_joy_button("jump", JOY_BUTTON_DPAD_UP)
	_ensure_joy_axis("jump", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_key("jump", KEY_SPACE)
	_ensure_key("jump", KEY_UP)
		
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
	flight_trail_particles.direction = Vector2.LEFT
	flight_trail_particles.position = Vector2(-35, -15)
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
	# M9: Precompute world bounds once instead of every frame
	_precompute_world_bounds()

var _planets_list: Array = []
# M9: Cached world bounds for out-of-bounds check
var _world_min: Vector2 = Vector2.ZERO
var _world_max: Vector2 = Vector2.ZERO

func _precompute_world_bounds() -> void:
	var min_x = INF; var max_x = -INF
	var min_y = INF; var max_y = -INF
	for p in _planets_list:
		if is_instance_valid(p):
			min_x = min(min_x, p.global_position.x)
			max_x = max(max_x, p.global_position.x)
			min_y = min(min_y, p.global_position.y)
			max_y = max(max_y, p.global_position.y)
	_world_min = Vector2(min_x, min_y)
	_world_max = Vector2(max_x, max_y)

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
		# H5/H6: Single sqrt, guard against zero-distance
		var dist_to_planet = diff.length()
		if dist_to_planet < 0.01:
			on_ground = true
		else:
			var surface_up = -diff / dist_to_planet
			var surface_radius = 100.0 * current_planet.scale.x
			var is_near_surface = dist_to_planet <= surface_radius + 5.0
			var vertical_speed = velocity.dot(surface_up)
			on_ground = is_on_floor() or (is_near_surface and vertical_speed <= 10.0)
		
	# 1. Find the nearest valid gravity source
	find_gravity_source(on_ground)
	
	# Handle speed buff activation
	if not is_menu_demo and not is_speed_buff_active and SaveSystem.speed_count > 0:
		var speed_just_pressed = (Input.is_action_pressed("speed") and not _shift_was_pressed) or _wants_to_speed or _joy_speed_just_pressed
		if speed_just_pressed:
			if SaveSystem.use_speed():
				is_speed_buff_active = true
				speed_used.emit()
				SoundManager.play_sfx("tether")
				_doomed = false
				_doom_timer = 0.0
				
				if current_planet == null:
					# Outer space burst — H5: avoid normalize+length, just scale
					velocity *= 1.8
				elif not on_ground:
					# Mid-air burst inside gravity
					velocity *= 1.5
				else:
					# On-ground immediate speedup
					current_speed = max_speed * 1.8
	
	if current_planet:
		# Clear any active grapple tether since we are inside gravity
		_tether_planet = null
		_tether_time_left = 0.0
		
		# 2. Calculate gravity direction — H5/H6: single sqrt, zero-distance guard
		var diff = current_planet.global_position - global_position
		var dist_to_center = diff.length()
		var gravity_dir: Vector2
		var surface_up: Vector2
		if dist_to_center < 0.01:
			# Player is exactly at planet center — push outward
			gravity_dir = Vector2.DOWN
			surface_up = Vector2.UP
		else:
			gravity_dir = diff / dist_to_center
			surface_up = -gravity_dir
		
		# 3. Rotate player to align with gravity
		var target_rotation = gravity_dir.angle() - PI/2
		if on_ground:
			rotation = target_rotation
		else:
			rotation = lerp_angle(rotation, target_rotation, 25.0 * delta)
		
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
				
			var cur_endless_scale = (1.0 + min(float(GameManager.endless_score) / 1000.0 * 0.25, 0.75)) if GameManager.is_endless_mode else 1.0
			var planet_top_speed = max_speed * cur_endless_scale * (1.8 if is_speed_buff_active else 1.0)
			
			# Guarantee capture: kill outward velocity and cap tangent velocity
			var outward_speed = velocity.dot(surface_up)
			if outward_speed > 0:
				velocity -= surface_up * outward_speed
				
			var tangent_speed = velocity.dot(surface_right)
			if abs(tangent_speed) > planet_top_speed:
				velocity -= surface_right * (tangent_speed - (planet_top_speed * sign(tangent_speed)))
				
		last_planet = current_planet
		
		# 4. Handle auto-drive with Option 2 (g ∝ v^2) zero-float scaling in Endless Mode
		var endless_scale = (1.0 + min(float(GameManager.endless_score) / 1000.0 * 0.25, 0.75)) if GameManager.is_endless_mode else 1.0
		var actual_max_speed = max_speed * endless_scale * (1.8 if is_speed_buff_active else 1.0)
		current_speed += brake_force * endless_scale * (1.0 if is_speed_buff_active else 0.5) * delta
		current_speed = clamp(current_speed, 0.0, actual_max_speed)
		
		# Re-evaluate on_ground using cached dist_to_center from above
		var surface_radius = 100.0 * current_planet.scale.x
		var is_near_surface = dist_to_center <= surface_radius + 5.0
		var vertical_speed = velocity.dot(surface_up)
		on_ground = is_on_floor() or (is_near_surface and vertical_speed <= 10.0)
		
		if not is_menu_demo and not GameManager.is_endless_mode and on_ground and current_planet != null and "type" in current_planet:
			if current_planet.type == 3: # PlanetType.CHALLENGE
				is_game_over = true
				if GameManager.has_box:
					GameManager.level_complete()
				else:
					GameManager.game_over("you forgot the delivery box!")
				return
		
		# Check game over condition
		if not is_menu_demo and not GameManager.is_endless_mode and current_speed <= 0.0 and on_ground:
			is_game_over = true
			GameManager.game_over("your bike stopped!")
			return

		
		# Create a falling-gravity well: gravity is much stronger when falling towards the planet.
		# Option 2: Gravity scales with endless_scale^2 (g ∝ v^2) so centrifugal force (v^2/r) is perfectly canceled!
		var endless_grav_scale = endless_scale * endless_scale
		var applied_gravity = gravity_strength * endless_grav_scale
		if not on_ground and velocity.dot(gravity_dir) > 0:
			applied_gravity = gravity_strength * endless_grav_scale * 3.0
		
		# Always apply gravity to ensure we stay pushed against the floor
		velocity += gravity_dir * applied_gravity * delta
		
		if on_ground and not was_on_ground:
			# Player just landed on a planet — very heavy haptics
			GameManager.trigger_haptic(0.50, 0.80, 0.30)
			_glide_used_this_flight = false  # Reset glide for next flight
			is_speed_buff_active = false     # Reset speed buff on landing
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
			var surface_r = 100.0 * current_planet.scale.x
			# Exact Analytical Orbit along circular planet surface
			var current_diff = global_position - current_planet.global_position
			var cur_angle = current_diff.angle()
			
			# Increment angle by exact angular speed: d_theta = (v / r) * forward_direction * delta
			var d_angle = (current_speed / surface_r) * forward_direction * delta
			var new_angle = cur_angle + d_angle
			
			var new_pos = current_planet.global_position + Vector2(cos(new_angle), sin(new_angle)) * surface_r
			global_position = new_pos
			
			# Align orientation and directions
			var new_surface_up = Vector2(cos(new_angle), sin(new_angle))
			var new_surface_right = Vector2(-sin(new_angle), cos(new_angle))
			
			rotation = new_angle + PI/2
			velocity = new_surface_right * current_speed * forward_direction
			
			# Check jump
			var jump_pressed = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump") or _wants_to_jump or _joy_jump_just_pressed
			if not is_menu_demo and jump_pressed and GameManager.is_gameplay_started:
				has_jumped = true
				on_ground = false
				_wants_to_jump = false
				_joy_jump_just_pressed = false
				
				# Jump haptic vibration
				GameManager.trigger_haptic(0.1, 0.15, 0.08)
				
				# Override the vertical velocity entirely to launch upwards (scales with endless_scale for identical arc)
				var actual_jump = jump_force * endless_scale * (1.25 if is_speed_buff_active else 1.0)
				velocity = (new_surface_right * current_speed * forward_direction) + (new_surface_up * actual_jump)
				SoundManager.play_sfx("jump")
		else:
			# Free Flight in gravity well
			velocity += surface_right * current_speed * forward_direction * delta * 0.5
			up_direction = surface_up
			floor_constant_speed = false
			floor_snap_length = 0.0
			move_and_slide()
		
	else:
		# ZERO GRAVITY STATE
		# Player floats in a straight line with their current velocity
		last_planet = null
		
		# Glide assist - pull toward nearest planet (requires available glide charges)
		if not is_menu_demo and SaveSystem.glide_count > 0:
			var just_pressed = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump") or _wants_to_jump or _joy_jump_just_pressed
			if just_pressed:
				var nearest = _find_nearest_planet()
				if nearest:
					_tether_planet = nearest
					_glide_used_this_flight = true
					SaveSystem.use_glide()
					glide_used.emit()
					_doomed = false
					_doom_timer = 0.0
					
					# Apply active thruster impulse towards nearest target planet
					var pull_dir = (nearest.global_position - global_position).normalized()
					velocity += pull_dir * 450.0
					
					SoundManager.start_sfx_loop("thruster")
					GameManager.trigger_haptic(0.12, 0.18, 0.12)
					
					# Grace timer if triggered by mobile touch tap
					if _wants_to_jump:
						_tether_time_left = 1.5
					else:
						_tether_time_left = 0.0
		
		# Apply tether pull in zero gravity
		if _tether_planet != null and is_instance_valid(_tether_planet):
			var is_holding = Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up") or Input.is_action_pressed("jump") or _joy_jump_pressed
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
				# Apply thruster force/pull
				var pull_dir = (_tether_planet.global_position - global_position).normalized()
				var pull_accel = 1200.0
				velocity += pull_dir * pull_accel * delta
				
				# Enable gas jet plume and orient it away from the planet (action-reaction)
				if thruster_particles != null:
					thruster_particles.emitting = true
					thruster_particles.global_rotation = (global_position - _tether_planet.global_position).angle()
				
				# Slingshot speed cap (600.0) — M10: use length_squared to avoid sqrt on fast path
				if velocity.length_squared() > 360000.0:
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
			var is_gliding = _tether_planet != null and is_instance_valid(_tether_planet)
			if is_gliding:
				_doomed = false
				_doom_timer = 0.0
				rotation = lerp_angle(rotation, velocity.angle(), 10.0 * delta)
				
			if not _doomed and not is_gliding and not is_heading_towards_any_planet():
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
		
			# --- Safety net: out-of-bounds fallback ---
			if GameManager.is_endless_mode:
				if global_position.y < -3000.0 or global_position.y > 3000.0 or global_position.x < -1000.0:
					is_game_over = true
					GameManager.game_over("you drifted into deep space!")
					return
			else:
				var buffer = 1500.0
				if global_position.x < _world_min.x - buffer or global_position.x > _world_max.x + buffer or global_position.y < _world_min.y - buffer or global_position.y > _world_max.y + buffer:
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
			
	# Update flight trail particles (scooter exhaust air)
	if is_instance_valid(flight_trail_particles):
		if velocity.length_squared() > 2500.0 and not is_game_over:
			flight_trail_particles.emitting = true
		else:
			flight_trail_particles.emitting = false

	update_sprite_region()
	# L6: Call queue_redraw() every frame to guarantee trajectory drawing is cleared immediately
	queue_redraw()
	
	_wants_to_jump = false # clear the input queue at the end of the frame
	_shift_was_pressed = Input.is_action_pressed("speed")
	_wants_to_speed = false
	_joy_jump_just_pressed = false
	_joy_speed_just_pressed = false

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
	if is_instance_valid(flight_trail_particles):
		if forward_direction < 0:
			flight_trail_particles.position = Vector2(35, -15)
			flight_trail_particles.direction = Vector2.RIGHT
		else:
			flight_trail_particles.position = Vector2(-35, -15)
			flight_trail_particles.direction = Vector2.LEFT

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
	var live_planets = get_tree().get_nodes_in_group("planets")
	for p in live_planets:
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
		# 200px generous buffer so we don't trigger too early on near-misses
		if dist_to_line < grav_radius + 200.0:
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
	var sim_endless_scale = (1.0 + min(float(GameManager.endless_score) / 1000.0 * 0.25, 0.75)) if GameManager.is_endless_mode else 1.0
	var sim_jump = jump_force * sim_endless_scale * (1.25 if is_speed_buff_active else 1.0)
	var sim_vel = (surface_right * current_speed * forward_direction) + (surface_up * -sim_jump)
	
	var sim_delta = 0.05
	trajectory_points.append(sim_pos)
	
	var live_planets = get_tree().get_nodes_in_group("planets")
	for i in range(120): # Simulate 6 seconds
		var nearest_planet = null
		var nearest_surface_dist = INF
		
		for p in live_planets:
			if not is_instance_valid(p): continue
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
			var sim_gravity = gravity_strength * (sim_endless_scale * sim_endless_scale)
			if "gravity_area" in nearest_planet and nearest_planet.gravity_area:
				sim_gravity = nearest_planet.gravity_area.gravity * (sim_endless_scale * sim_endless_scale)
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
	var live_planets = get_tree().get_nodes_in_group("planets")
	for p in live_planets:
		if is_instance_valid(p):
			var dist = global_position.distance_to(p.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = p
	return nearest

func _ensure_joy_button(action: String, btn_index: JoyButton):
	if not InputMap.has_action(action): return
	var has_btn = false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton and ev.button_index == btn_index:
			has_btn = true
			break
	if not has_btn:
		var ev = InputEventJoypadButton.new()
		ev.button_index = btn_index
		InputMap.action_add_event(action, ev)

func _ensure_joy_axis(action: String, axis: JoyAxis, dir: float):
	if not InputMap.has_action(action): return
	var has_axis = false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadMotion and ev.axis == axis and sign(ev.axis_value) == sign(dir):
			has_axis = true
			break
	if not has_axis:
		var ev = InputEventJoypadMotion.new()
		ev.axis = axis
		ev.axis_value = dir
		InputMap.action_add_event(action, ev)

func _ensure_key(action: String, keycode: Key):
	if not InputMap.has_action(action): return
	var has_key = false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.keycode == keycode:
			has_key = true
			break
	if not has_key:
		var ev = InputEventKey.new()
		ev.keycode = keycode
		InputMap.action_add_event(action, ev)

