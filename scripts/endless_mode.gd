extends Node2D

@onready var planets_node = $Planets
@onready var player = $Player2D
@onready var camera = $Camera2D

var planet_scene = preload("res://scenes/planet.tscn")
var ruby_scene = preload("res://scenes/ruby.tscn")

var next_spawn_x: float = 600.0
var max_distance_reached: int = 0
var last_milestone_shown: int = 0

var active_planets: Array = []
var active_rubies: Array = []

# HUD Labels
var score_label: Label
var best_label: Label

func _ready() -> void:
	GameManager.is_endless_mode = true
	GameManager.is_gameplay_started = true
	GameManager._game_ended = false
	GameManager.endless_score = 0
	GameManager.endless_deliveries = 0
	GameManager.has_box = true
	GameManager.box_health = 100.0
	
	# Stop menu music so in-game level music plays from $BGM via InGameUI
	BgmManager.stop_menu_music()
	
	if is_instance_valid(camera):
		camera.global_position = Vector2(400, 450)
		camera.zoom = Vector2(0.5, 0.5)
	
	_setup_hud()
	_generate_initial_world()

func _setup_hud() -> void:
	var hud_layer = CanvasLayer.new()
	hud_layer.layer = 2 # Behind InGameUI (layer = 20)
	add_child(hud_layer)
	
	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	hud_layer.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 25)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)
	
	# Distance Panel (Score = Distance in meters)
	var score_panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	score_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_label = Label.new()
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_label.text = "DISTANCE: 0m"
	score_label.add_theme_font_override("font", preload("res://assets/game_font.ttf"))
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	score_panel.add_child(score_label)
	hbox.add_child(score_panel)
	
	# Best Distance Panel
	var best_panel = UIFactory.create_glass_panel(UIFactory.PURPLE_COLOR)
	best_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	best_label = Label.new()
	best_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	best_label.text = "BEST: %dm" % SaveSystem.endless_high_score
	best_label.add_theme_font_override("font", preload("res://assets/game_font.ttf"))
	best_label.add_theme_font_size_override("font_size", 20)
	best_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	best_panel.add_child(best_label)
	hbox.add_child(best_panel)
	
	GameManager.endless_score_changed.connect(_on_score_changed)

func _on_score_changed(score: int, _deliveries: int) -> void:
	if is_instance_valid(score_label):
		score_label.text = "DISTANCE: %dm" % score
	if score > SaveSystem.endless_high_score:
		if is_instance_valid(best_label):
			best_label.text = "BEST: %dm" % score
			best_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

func _process(delta: float) -> void:
	if is_instance_valid(player) and not player.is_game_over and not GameManager._game_ended:
		# Continuously track distance traveled in meters
		var current_m = max(0, int((player.global_position.x - 200.0) / 10.0))
		if current_m > max_distance_reached:
			max_distance_reached = current_m
			GameManager.endless_score = max_distance_reached
			GameManager.endless_score_changed.emit(max_distance_reached, 0)
			SaveSystem.save_endless_score(max_distance_reached)
			AchievementManager.on_endless_distance(max_distance_reached)
			
			# Distance Milestone celebration popup every 500 meters!
			var milestone = (max_distance_reached / 500) * 500
			if milestone >= 500 and milestone > last_milestone_shown:
				last_milestone_shown = milestone
				_show_floating_popup("+%dm DISTANCE MILESTONE!" % milestone, player.global_position)
				SoundManager.play_sfx("ruby")
				GameManager.trigger_haptic(0.3, 0.6, 0.2)
		
		# --- Camera Movement (Matching Levels / Campaign Mode) ---
		if is_instance_valid(camera):
			var ui = get_tree().get_first_node_in_group("in_game_ui")
			var is_map = (ui != null and "is_viewing_map" in ui and ui.is_viewing_map)
			
			if is_map:
				# Zoom out for map view
				var map_zoom = Vector2(0.25, 0.25)
				camera.zoom = camera.zoom.lerp(map_zoom, 5.0 * delta)
				var center_pos = Vector2(player.global_position.x + 400.0, 450.0)
				camera.global_position = camera.global_position.lerp(center_pos, 6.0 * delta)
			else:
				var default_zoom = Vector2(0.5, 0.5)
				camera.zoom = camera.zoom.lerp(default_zoom, 5.0 * delta)
				
				var look_ahead := 200.0
				var target_x: float
				var target_y: float
				
				if is_instance_valid(player.current_planet) and player.on_ground:
					# While riding a planet, lock the camera to the planet so the screen doesn't spin or drift (same as Levels Mode)
					target_x = player.current_planet.global_position.x + look_ahead
					target_y = player.current_planet.global_position.y
				else:
					# While jumping / flying, follow the player through space with the same offset
					target_x = player.global_position.x + look_ahead
					target_y = player.global_position.y
					
				var target = Vector2(target_x, target_y)
				camera.global_position = camera.global_position.lerp(target, 6.0 * delta)
				
			# Vertical Abyss Death
			if player.global_position.y > 1800.0 or player.global_position.y < -1000.0:
				GameManager.game_over("lost in deep space!")
				return
		
		# Infinite Procedural Planet Generation as player travels forward
		if player.global_position.x + 2200.0 > next_spawn_x:
			_spawn_next_target_section()

func _generate_initial_world() -> void:
	# Clear existing
	for child in planets_node.get_children():
		child.queue_free()
		
	active_planets.clear()
	active_rubies.clear()
		
	# Spawn Starting Home Planet (Green / Blue, NO RED)
	var home_p = planet_scene.instantiate()
	home_p.global_position = Vector2(200, 450)
	home_p.type = 0 # PlanetType.BASIC (Green/Blue, never Red)
	planets_node.add_child(home_p)
	home_p.add_to_group("planets")
	active_planets.append(home_p)
	
	# Position Player on Home Planet
	player.global_position = Vector2(200, 260)
	next_spawn_x = 200.0
	
	# Spawn Initial Random Planet Constellation
	for i in range(4):
		_spawn_next_target_section()

func _spawn_next_target_section() -> void:
	# Generate 2 random non-overlapping planets with guaranteed minimum 550px separation
	var count_to_spawn = randi_range(1, 2)
	for k in range(count_to_spawn):
		var valid_pos = Vector2.ZERO
		var found_valid = false
		
		# Try up to 30 random positions to find a clean non-overlapping spot
		for attempt in range(30):
			var cand_x = next_spawn_x + randf_range(520.0, 780.0)
			var cand_y = randf_range(150.0, 680.0)
			var cand_pos = Vector2(cand_x, cand_y)
			
			var is_overlap = false
			for p in active_planets:
				if is_instance_valid(p):
					if cand_pos.distance_to(p.global_position) < 550.0:
						is_overlap = true
						break
			
			if not is_overlap:
				valid_pos = cand_pos
				found_valid = true
				break
		
		if found_valid:
			_instantiate_planet(valid_pos, randi() % 3)
			next_spawn_x = max(next_spawn_x, valid_pos.x)
			
		else:
			# Fallback clean offset if all 30 random attempts were tight
			next_spawn_x += randf_range(650.0, 800.0)
			var fallback_pos = Vector2(next_spawn_x, randf_range(180.0, 640.0))
			_instantiate_planet(fallback_pos, randi() % 3)

	_cleanup_distant_objects()

func _instantiate_planet(pos: Vector2, p_type: int) -> void:
	var p = planet_scene.instantiate()
	p.global_position = pos
	p.type = p_type # Types 0, 1, 2 only (NO RED PLANET)
	planets_node.add_child(p)
	p.add_to_group("planets")
	active_planets.append(p)
	
	# Spawn rubies scaled to planet surface radius
	if randf() > 0.35:
		var p_scale = 1.5 if p_type == 0 else (1.2 if p_type == 1 else 0.9)
		_spawn_ruby_cluster(pos, p_scale)

func _spawn_ruby_cluster(center: Vector2, planet_scale: float = 1.0) -> void:
	var surface_r = 100.0 * planet_scale
	var count = randi_range(2, 4)
	for i in range(count):
		var ruby = ruby_scene.instantiate()
		var angle = (float(i) / count) * TAU
		var offset = Vector2(cos(angle), sin(angle)) * (surface_r + randf_range(35.0, 75.0))
		ruby.global_position = center + offset
		add_child(ruby)
		active_rubies.append(ruby)

func _show_floating_popup(msg: String, pos: Vector2) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_override("font", preload("res://assets/game_font.ttf"))
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	lbl.global_position = pos + Vector2(-100, -100)
	add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "global_position:y", pos.y - 180, 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)

func _cleanup_distant_objects() -> void:
	if not is_instance_valid(player):
		return
	var min_x = player.global_position.x - 2200.0
	
	for i in range(active_planets.size() - 1, -1, -1):
		var p = active_planets[i]
		if is_instance_valid(p) and p.global_position.x < min_x:
			active_planets.remove_at(i)
			p.queue_free()
			
	for i in range(active_rubies.size() - 1, -1, -1):
		var r = active_rubies[i]
		if is_instance_valid(r) and r.global_position.x < min_x:
			active_rubies.remove_at(i)
			r.queue_free()
