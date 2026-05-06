extends CanvasLayer

@onready var bgm = $"../BGM"
@onready var player = $"../Player2D"

var is_viewing_map: bool = false
@onready var level_camera = $"../Camera2D"
# Fixed zoom - same size for ALL levels (matches level 1 look)
var default_zoom = Vector2(0.5, 0.5)
var level_center_pos = Vector2.ZERO
var map_zoom = Vector2(0.25, 0.25)

# Level bounds for map view and asteroid spawning
var level_min = Vector2.ZERO
var level_max = Vector2.ZERO

var score_label: Label
var health_label: Label
var view_map_btn: Button
var hint_button: Button
var hint_used: bool = false

func _ready():
	if is_instance_valid(level_camera):
		# Calculate level bounds from planet positions
		var planets = get_tree().get_nodes_in_group("planets")
		if planets.size() > 0:
			var min_x = INF
			var max_x = -INF
			var min_y = INF
			var max_y = -INF
			for p in planets:
				min_x = min(min_x, p.global_position.x)
				max_x = max(max_x, p.global_position.x)
				min_y = min(min_y, p.global_position.y)
				max_y = max(max_y, p.global_position.y)
			
			level_min = Vector2(min_x - 500, min_y - 500)
			level_max = Vector2(max_x + 500, max_y + 500)
			level_center_pos = (level_min + level_max) / 2.0
			
			# Calculate map zoom to fit entire level
			var level_width = level_max.x - level_min.x
			var level_height = level_max.y - level_min.y
			var zoom_x = 1280.0 / level_width
			var zoom_y = 720.0 / level_height
			map_zoom = Vector2(min(zoom_x, zoom_y) * 0.85, min(zoom_x, zoom_y) * 0.85)
			map_zoom = Vector2(clamp(map_zoom.x, 0.1, 0.4), clamp(map_zoom.y, 0.1, 0.4))
		
		# Fixed zoom for all levels - same as level 1
		level_camera.zoom = default_zoom
		
		# Start camera on the player
		if is_instance_valid(player):
			level_camera.global_position = player.global_position
	
	# Setup Score Panel
	var score_panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	var score_hbox = HBoxContainer.new()
	score_hbox.add_theme_constant_override("separation", 10)
	
	var ruby_icon = TextureRect.new()
	ruby_icon.texture = ResourceManager.get_texture("res://assets/ruby.png")
	ruby_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ruby_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruby_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ruby_icon.custom_minimum_size = Vector2(30, 30)
	
	score_label = Label.new()
	score_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	score_label.add_theme_constant_override("outline_size", 5)
	
	score_hbox.add_child(ruby_icon)
	score_hbox.add_child(score_label)
	score_panel.add_child(score_hbox)
	
	var score_margin = MarginContainer.new()
	score_margin.add_theme_constant_override("margin_left", 20)
	score_margin.add_theme_constant_override("margin_top", 20)
	score_margin.add_child(score_panel)
	add_child(score_margin)
	
	# Setup Health Panel
	var health_panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	var health_hbox = HBoxContainer.new()
	health_hbox.add_theme_constant_override("separation", 8)
	
	var box_icon = TextureRect.new()
	box_icon.texture = ResourceManager.get_texture("res://assets/delivery_box.png")
	box_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	box_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box_icon.custom_minimum_size = Vector2(76, 32)
	
	health_label = Label.new()
	health_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	health_label.add_theme_font_size_override("font_size", 32)
	health_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	health_label.add_theme_constant_override("outline_size", 5)
	
	health_hbox.add_child(box_icon)
	health_hbox.add_child(health_label)
	health_panel.add_child(health_hbox)
	
	var health_margin = MarginContainer.new()
	health_margin.add_theme_constant_override("margin_left", 20)
	health_margin.add_theme_constant_override("margin_top", 90)
	health_margin.add_child(health_panel)
	add_child(health_margin)
	
	# Setup View Map Button
	view_map_btn = UIFactory.create_glass_button("map", UIFactory.BLUE_COLOR, "res://assets/map_icon.jpg")
	view_map_btn.pressed.connect(_on_view_map_pressed)
	
	var map_margin = MarginContainer.new()
	map_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	map_margin.add_theme_constant_override("margin_top", 20)
	map_margin.add_theme_constant_override("margin_right", 40)
	map_margin.add_child(view_map_btn)
	add_child(map_margin)
	
	# Setup Hint Button
	hint_button = UIFactory.create_glass_button("hint", UIFactory.GOLD_COLOR, "res://assets/hint_icon.jpg")
	hint_button.button_down.connect(_on_hint_pressed)
	hint_button.button_up.connect(_on_hint_released)
	
	var hint_margin = MarginContainer.new()
	hint_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint_margin.add_theme_constant_override("margin_bottom", 20)
	hint_margin.add_theme_constant_override("margin_right", 40)
	hint_margin.add_child(hint_button)
	add_child(hint_margin)
	
	# Setup Level Indicator
	var level_panel = UIFactory.create_glass_panel()
	var level_label = Label.new()
	level_label.text = "level %d" % GameManager.current_level
	level_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	level_label.add_theme_font_size_override("font_size", 40)
	level_panel.add_child(level_label)
	
	var level_margin = MarginContainer.new()
	level_margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	level_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	level_margin.add_theme_constant_override("margin_top", 20)
	level_margin.add_child(level_panel)
	add_child(level_margin)
	
	# Remove old UI
	if has_node("MarginContainer"): $MarginContainer.queue_free()
	if has_node("HealthMargin"): $HealthMargin.queue_free()
	if has_node("ViewMapMargin"): $ViewMapMargin.queue_free()
	if has_node("HintMargin"): $HintMargin.queue_free()

func _process(delta: float):
	if is_instance_valid(health_label):
		health_label.text = "box health: %d%%" % int(GameManager.box_health)
	if is_instance_valid(score_label):
		score_label.text = "score: %d" % GameManager.current_score
	
	if is_instance_valid(level_camera):
		if is_viewing_map:
			# Zoom out to show full level
			level_camera.zoom = level_camera.zoom.lerp(map_zoom, 5.0 * delta)
			level_camera.global_position = level_camera.global_position.lerp(level_center_pos, 8.0 * delta)
		else:
			level_camera.zoom = level_camera.zoom.lerp(default_zoom, 5.0 * delta)
			if is_instance_valid(player):
				if player.current_planet != null and is_instance_valid(player.current_planet):
					# On a planet: lock camera to the planet center
					level_camera.global_position = level_camera.global_position.lerp(player.current_planet.global_position, 8.0 * delta)
				else:
					# In zero gravity: follow the player
					level_camera.global_position = level_camera.global_position.lerp(player.global_position, 6.0 * delta)

func _on_hint_pressed():
	if hint_used:
		return
	hint_used = true
	if is_instance_valid(player):
		player.show_trajectory = true
	# Fade out the button after activation
	var tween = create_tween()
	tween.tween_property(hint_button, "modulate:a", 0.3, 0.5)

func _on_hint_released():
	pass # Trajectory stays visible until player lands

func _on_view_map_pressed():
	is_viewing_map = !is_viewing_map
