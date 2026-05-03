extends CanvasLayer

@onready var bgm = $"../BGM"
@onready var player = $"../Player2D"

var is_viewing_map: bool = false
@onready var level_camera = $"../Camera2D"
var default_zoom = Vector2.ZERO
var level_center_pos = Vector2.ZERO
var camera_target_pos = Vector2.ZERO

var min_cam_x: float = 0.0
var max_cam_x: float = 0.0
var pan_step: float = 2000.0
var left_btn: Button
var right_btn: Button

var score_label: Label
var health_label: Label
var view_map_btn: Button
var hint_button: Button
var slider: HSlider

func create_glass_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_right = 15
	style.corner_radius_bottom_left = 15
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.6, 1.0, 0.5)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel
	
func create_glass_button(text: String, color: Color, icon_path: String = "") -> Button:
	var btn = Button.new()
	btn.text = " " + text
	
	if icon_path != "":
		var tex = load(icon_path)
		if tex:
			btn.icon = tex
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 30)
			
	btn.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	btn.add_theme_font_size_override("font_size", 28)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.4)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_right = 15
	style.corner_radius_bottom_left = 15
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(color.r, color.g, color.b, 0.7)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", style)
	return btn

func _ready():
	if is_instance_valid(level_camera):
		# Calculate bounds to determine exact vertical zoom needed
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
			
			# Fit the vertical height perfectly, with padding for gravity fields and UI (top UI needs more padding)
			var required_height = (max_y - min_y) + 1200.0
			var target_zoom = 720.0 / required_height
			
			# Clamp zoom so it's never too close or ridiculously small
			var final_zoom = clamp(target_zoom, 0.2, 0.5)
			default_zoom = Vector2(final_zoom, final_zoom)
			level_camera.zoom = default_zoom
			level_center_pos = level_camera.global_position
			camera_target_pos = level_center_pos
			
			var screen_w = 1280.0 / final_zoom
			var half_w = screen_w / 2.0
			var planet_padding = 500.0 # Extra space on left and right
			pan_step = screen_w * 0.8 # Pan by 80% of screen width
			
			min_cam_x = min_x - planet_padding + half_w
			max_cam_x = max_x + planet_padding - half_w
			if min_cam_x > max_cam_x:
				min_cam_x = level_center_pos.x
				max_cam_x = level_center_pos.x
			
			camera_target_pos.x = min_cam_x
			level_camera.global_position.x = min_cam_x
		
	# Setup Score Panel (Top Left)
	var score_panel = create_glass_panel()
	var score_style = score_panel.get_theme_stylebox("panel").duplicate()
	score_style.border_color = Color(1, 0.8, 0.2, 0.8)
	score_panel.add_theme_stylebox_override("panel", score_style)
	var score_hbox = HBoxContainer.new()
	score_hbox.add_theme_constant_override("separation", 10)
	
	var ruby_icon = TextureRect.new()
	ruby_icon.texture = load("res://assets/ruby.png")
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
	
	# Setup Health Panel (Below Score)
	var health_panel = create_glass_panel()
	var health_style = health_panel.get_theme_stylebox("panel").duplicate()
	health_style.border_color = Color(1, 0.8, 0.2, 0.8)
	health_panel.add_theme_stylebox_override("panel", health_style)
	
	var health_hbox = HBoxContainer.new()
	health_hbox.add_theme_constant_override("separation", 8)
	
	var box_icon = TextureRect.new()
	box_icon.texture = load("res://assets/delivery_box.png")
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
	
	# Setup View Map Button (Top Right)
	view_map_btn = create_glass_button("map", Color(0.2, 0.6, 1.0), "res://assets/map_icon.jpg")
	view_map_btn.pressed.connect(_on_view_map_pressed)
	
	var map_margin = MarginContainer.new()
	map_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	map_margin.add_theme_constant_override("margin_top", 20)
	map_margin.add_theme_constant_override("margin_right", 40)
	map_margin.add_child(view_map_btn)
	add_child(map_margin)
	
	# Setup Hint Button (Bottom Right)
	hint_button = create_glass_button("hint", Color(1.0, 0.8, 0.2), "res://assets/hint_icon.jpg")
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
	
	# Setup Level Indicator (Top Center)
	var level_panel = create_glass_panel()
	var level_label = Label.new()
	level_label.text = "level %d" % GameManager.current_level
	level_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	level_label.add_theme_font_size_override("font_size", 40)
	level_label.add_theme_color_override("font_color", Color(1, 1, 1))
	level_label.add_theme_constant_override("outline_size", 6)
	level_panel.add_child(level_label)
	
	var level_margin = MarginContainer.new()
	level_margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	level_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	level_margin.add_theme_constant_override("margin_top", 20)
	level_margin.add_child(level_panel)
	add_child(level_margin)
	
	# Remove old pre-generated UI from python script safely
	if has_node("MarginContainer"): $MarginContainer.queue_free()
	if has_node("HealthMargin"): $HealthMargin.queue_free()
	if has_node("ViewMapMargin"): $ViewMapMargin.queue_free()
	if has_node("HintMargin"): $HintMargin.queue_free()
	
	# Tutorial Overlay for Level 1
	if GameManager.current_level == 1:
		var tutorial_panel = create_glass_panel()
		# Duplicate stylebox so we don't modify the global shared instance
		var tut_style = tutorial_panel.get_theme_stylebox("panel").duplicate()
		tut_style.bg_color = Color(0.1, 0.2, 0.4, 0.8)
		tut_style.border_color = Color(0.3, 0.8, 1.0, 0.8)
		tut_style.content_margin_left = 40
		tut_style.content_margin_right = 40
		tut_style.content_margin_top = 30
		tut_style.content_margin_bottom = 30
		tutorial_panel.add_theme_stylebox_override("panel", tut_style)
		
		var tut_vbox = VBoxContainer.new()
		tut_vbox.add_theme_constant_override("separation", 20)
		
		var title = Label.new()
		title.text = "how to play"
		title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		title.add_theme_font_size_override("font_size", 50)
		title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		title.add_theme_color_override("font_outline_color", Color.BLACK)
		title.add_theme_constant_override("outline_size", 8)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tut_vbox.add_child(title)
		
		var msg = Label.new()
		msg.text = "• tap space or up to jump!\n• protect your delivery box!\n• each jump to a planet: -10% health\n• collect rubies for score\n• reach the finish flag"
		msg.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		msg.add_theme_font_size_override("font_size", 34)
		msg.add_theme_color_override("font_color", Color.WHITE)
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tut_vbox.add_child(msg)
		
		var close_lbl = Label.new()
		close_lbl.text = "(this message will fade out)"
		close_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		close_lbl.add_theme_font_size_override("font_size", 24)
		close_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tut_vbox.add_child(close_lbl)
		
		tutorial_panel.add_child(tut_vbox)
		
		var tut_margin = MarginContainer.new()
		tut_margin.name = "TutorialMargin"
		tut_margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		tut_margin.add_child(tutorial_panel)
		add_child(tut_margin)
		
		# Auto-hide after 6 seconds
		var tween = create_tween()
		tween.tween_interval(5.0)
		tween.tween_property(tut_margin, "modulate:a", 0.0, 1.5)
		tween.tween_callback(tut_margin.queue_free)
		
	# Setup Camera Panning Buttons
	if max_cam_x > min_cam_x + 100:
		left_btn = create_glass_button("<", Color(0.8, 0.8, 0.8))
		left_btn.pressed.connect(func(): camera_target_pos.x = clamp(camera_target_pos.x - pan_step, min_cam_x, max_cam_x))
		var left_margin = MarginContainer.new()
		left_margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		left_margin.add_theme_constant_override("margin_left", 30)
		left_margin.add_child(left_btn)
		add_child(left_margin)
		
		right_btn = create_glass_button(">", Color(0.8, 0.8, 0.8))
		right_btn.pressed.connect(func(): camera_target_pos.x = clamp(camera_target_pos.x + pan_step, min_cam_x, max_cam_x))
		var right_margin = MarginContainer.new()
		right_margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		right_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		right_margin.add_theme_constant_override("margin_right", 30)
		right_margin.add_child(right_btn)
		add_child(right_margin)

func _process(delta: float):
	if is_instance_valid(health_label):
		health_label.text = "box health: %d%%" % int(GameManager.box_health)
		
	if is_instance_valid(score_label):
		score_label.text = "score: %d" % GameManager.current_score
		
	if is_instance_valid(level_camera):
		# Default gameplay zoom is closer (0.6), Map zoom is zoomed out (0.25)
		var target_zoom = Vector2(0.25, 0.25) if is_viewing_map else default_zoom
		level_camera.zoom = level_camera.zoom.lerp(target_zoom, 5.0 * delta)
		
		var target_pos = level_center_pos if is_viewing_map else camera_target_pos
		level_camera.global_position = level_camera.global_position.lerp(target_pos, 8.0 * delta)

func _on_hint_pressed():
	if is_instance_valid(player):
		player.show_trajectory = true

func _on_hint_released():
	if is_instance_valid(player):
		player.show_trajectory = false

func _on_view_map_pressed():
	is_viewing_map = !is_viewing_map

func _on_health_changed(new_health: float):
	if is_instance_valid(health_label):
		health_label.text = "box health: %d%%" % int(new_health)
