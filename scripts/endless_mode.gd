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
	hbox.add_theme_constant_override("separation", 25)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)
	
	# Distance Panel (Score = Distance in meters)
	var score_panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	score_label = Label.new()
	score_label.text = "DISTANCE: 0m"
	score_label.add_theme_font_override("font", preload("res://assets/game_font.ttf"))
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	score_panel.add_child(score_label)
	hbox.add_child(score_panel)
	
	# Best Distance Panel
	var best_panel = UIFactory.create_glass_panel(UIFactory.PURPLE_COLOR)
	best_label = Label.new()
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

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		# Continuously track distance traveled in meters
		var current_m = max(0, int((player.global_position.x - 200.0) / 10.0))
		if current_m > max_distance_reached:
			max_distance_reached = current_m
			GameManager.endless_score = max_distance_reached
			GameManager.endless_score_changed.emit(max_distance_reached, 0)
			SaveSystem.save_endless_score(max_distance_reached)
			
			# Distance Milestone celebration popup every 500 meters!
			var milestone = (max_distance_reached / 500) * 500
			if milestone >= 500 and milestone > last_milestone_shown:
				last_milestone_shown = milestone
				_show_floating_popup("+%dm DISTANCE MILESTONE!" % milestone, player.global_position)
				SoundManager.play_sfx("ruby")
				GameManager.trigger_haptic(0.3, 0.6, 0.2)
		
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
	
	# Spawn First Constellation Section with 650px open space gaps
	_spawn_next_target_section()

func _spawn_next_target_section() -> void:
	# Open space gap between planets (600px - 750px between each planet center)
	var gap_1 = randf_range(600.0, 750.0)
	var gap_2 = randf_range(650.0, 800.0)
	
	# Intermediate planet in open space (Types 0, 1, 2 only — NO RED PLANET)
	var inter_p = planet_scene.instantiate()
	var inter_x = next_spawn_x + gap_1
	var inter_y = randf_range(180.0, 680.0)
	inter_p.global_position = Vector2(inter_x, inter_y)
	inter_p.type = randi() % 3 # Types 0, 1, 2 only (NO RED PLANET)
	planets_node.add_child(inter_p)
	inter_p.add_to_group("planets")
	active_planets.append(inter_p)
	
	# Spawn rubies in space near intermediate planet
	if randf() > 0.3:
		_spawn_ruby_cluster(Vector2(inter_x, inter_y))

	# Target Constellation Planet across open space (Types 0, 1, 2 only — NO RED PLANET)
	next_spawn_x = inter_x + gap_2
	var target_y = randf_range(200.0, 640.0)
	var target_p = planet_scene.instantiate()
	target_p.global_position = Vector2(next_spawn_x, target_y)
	target_p.type = randi() % 3 # Types 0, 1, 2 only (NO RED PLANET)
	planets_node.add_child(target_p)
	target_p.add_to_group("planets")
	active_planets.append(target_p)
	
	_cleanup_distant_objects()

func _spawn_ruby_cluster(center: Vector2) -> void:
	var count = randi_range(2, 4)
	for i in range(count):
		var ruby = ruby_scene.instantiate()
		var angle = (float(i) / count) * TAU
		var offset = Vector2(cos(angle), sin(angle)) * randf_range(160.0, 220.0)
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
