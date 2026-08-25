extends Node2D

@onready var planets_node = $Planets
@onready var player = $Player2D
@onready var camera = $Camera2D

var planet_scene = preload("res://scenes/planet.tscn")
var ruby_scene = preload("res://scenes/ruby.tscn")

var current_target_planet: Node2D = null
var next_spawn_x: float = 600.0

var active_planets: Array = []
var active_rubies: Array = []

# HUD Labels
var score_label: Label
var best_label: Label
var delivery_label: Label

func _ready() -> void:
	GameManager.is_endless_mode = true
	GameManager.endless_score = 0
	GameManager.endless_deliveries = 0
	GameManager.has_box = true
	GameManager.box_health = 100.0
	
	BgmManager.play_menu_music()
	
	_setup_hud()
	_generate_initial_world()

func _setup_hud() -> void:
	var hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	hud_layer.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)
	
	# Score Panel
	var score_panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	score_label = Label.new()
	score_label.text = "SCORE: 0"
	score_label.add_theme_font_override("font", preload("res://assets/game_font.ttf"))
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	score_panel.add_child(score_label)
	hbox.add_child(score_panel)
	
	# Best Score Panel
	var best_panel = UIFactory.create_glass_panel(UIFactory.PURPLE_COLOR)
	best_label = Label.new()
	best_label.text = "BEST: %d" % SaveSystem.endless_high_score
	best_label.add_theme_font_override("font", preload("res://assets/game_font.ttf"))
	best_label.add_theme_font_size_override("font_size", 20)
	best_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	best_panel.add_child(best_label)
	hbox.add_child(best_panel)
	
	# Deliveries Panel
	var del_panel = UIFactory.create_glass_panel(UIFactory.BLUE_COLOR)
	delivery_label = Label.new()
	delivery_label.text = "DELIVERIES: 0"
	delivery_label.add_theme_font_override("font", preload("res://assets/game_font.ttf"))
	delivery_label.add_theme_font_size_override("font_size", 20)
	delivery_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	del_panel.add_child(delivery_label)
	hbox.add_child(del_panel)
	
	GameManager.endless_score_changed.connect(_on_score_changed)

func _on_score_changed(score: int, deliveries: int) -> void:
	if is_instance_valid(score_label):
		score_label.text = "SCORE: %d" % score
	if is_instance_valid(delivery_label):
		delivery_label.text = "DELIVERIES: %d" % deliveries
	if score > SaveSystem.endless_high_score:
		if is_instance_valid(best_label):
			best_label.text = "BEST: %d" % score
			best_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

func _process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(camera):
		# Smooth camera follow ahead of player
		var target_pos = player.global_position + Vector2(200, 0)
		camera.global_position = camera.global_position.lerp(target_pos, 0.08)
		
		# Check target planet delivery collision distance
		if is_instance_valid(current_target_planet):
			var target_radius = 110.0 * current_target_planet.scale.x
			var dist = player.global_position.distance_to(current_target_planet.global_position)
			if dist <= target_radius + 35.0:
				_on_package_delivered()
		
		# Infinite Procedural Planet Generation as player travels forward
		if player.global_position.x + 1600.0 > next_spawn_x:
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
	next_spawn_x = 550.0
	
	# Spawn First Nearby Target Section
	_spawn_next_target_section()

func _spawn_next_target_section() -> void:
	var del_count = GameManager.endless_deliveries
	
	# Tight, nearby spacing between planets (320.0 to 420.0) so planets are close!
	var step_distance = randf_range(320.0, 420.0)
	var spawn_y = randf_range(380.0, 520.0)
	
	# Spawn 1 nearby intermediate planet (Types 0, 1, 2 only — NO RED PLANET)
	var inter_p = planet_scene.instantiate()
	var inter_x = next_spawn_x + (step_distance * 0.5)
	var inter_y = randf_range(360.0, 540.0)
	inter_p.global_position = Vector2(inter_x, inter_y)
	inter_p.type = randi() % 3 # Types 0, 1, 2 only (NO RED)
	planets_node.add_child(inter_p)
	inter_p.add_to_group("planets")
	active_planets.append(inter_p)
	
	# Spawn rubies orbiting intermediate planet
	if randf() > 0.4:
		_spawn_ruby_cluster(Vector2(inter_x, inter_y))

	# Spawn Target Planet (Types 0, 1, 2 only — NO RED PLANET)
	next_spawn_x += step_distance
	var target_p = planet_scene.instantiate()
	target_p.global_position = Vector2(next_spawn_x, spawn_y)
	target_p.type = (del_count % 3) # Types 0, 1, 2 only (NO RED)
	planets_node.add_child(target_p)
	target_p.add_to_group("planets")
	active_planets.append(target_p)
	current_target_planet = target_p
	
	# Cleanup old planets far behind player to preserve 60 FPS
	_cleanup_distant_objects()

func _spawn_ruby_cluster(center: Vector2) -> void:
	var count = randi_range(2, 3)
	for i in range(count):
		var ruby = ruby_scene.instantiate()
		var angle = (float(i) / count) * TAU
		var offset = Vector2(cos(angle), sin(angle)) * randf_range(140.0, 180.0)
		ruby.global_position = center + offset
		add_child(ruby)
		active_rubies.append(ruby)

func _on_package_delivered() -> void:
	SoundManager.play_sfx("ruby")
	GameManager.trigger_haptic(0.4, 0.8, 0.3)
	
	# Points & Repair Box
	GameManager.endless_deliveries += 1
	var bonus_points = 100 + (GameManager.endless_deliveries * 25)
	GameManager.add_endless_score(bonus_points)
	GameManager.box_health = clamp(GameManager.box_health + 30.0, 0.0, 100.0)
	GameManager.health_changed.emit(GameManager.box_health)
	
	# Floating Score Indicator
	if is_instance_valid(current_target_planet):
		_show_floating_popup("+%d DELIVERED!" % bonus_points, current_target_planet.global_position)
		current_target_planet = null # Reset until next section target is reached
	
	# Check High Score
	SaveSystem.save_endless_score(GameManager.endless_score)
	
	# Generate next nearby target section
	_spawn_next_target_section()

func _show_floating_popup(msg: String, pos: Vector2) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_override("font", preload("res://assets/game_font.ttf"))
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	lbl.global_position = pos + Vector2(-80, -100)
	add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "global_position:y", pos.y - 180, 1.0)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
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
