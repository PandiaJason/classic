extends CanvasLayer

@onready var bgm = $"../BGM"
@onready var player = $"../Player2D"

var is_viewing_map: bool = true
@onready var level_camera = $"../Camera2D"
# Fixed zoom - same size for ALL levels (matches level 1 look)
var default_zoom = Vector2(0.5, 0.5)
var level_center_pos = Vector2.ZERO
var map_zoom = Vector2(0.25, 0.25)

# Level bounds for map view and asteroid spawning
var level_min = Vector2.ZERO
var level_max = Vector2.ZERO

var ruby_label: Label
var health_label: Label
var view_map_btn: Button
var hint_button: Button
var hint_used: bool = false
var map_timer = null
var glide_button: Button
var speed_button: Button

var is_paused: bool = false
var pause_overlay: Control = null

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var _trigger_map_pressed: bool = false
var _touch_start_pos: Dictionary = {}
var _touch_start_time: Dictionary = {}

func _input(event: InputEvent) -> void:
	if not GameManager.is_gameplay_started:
		return
	if is_paused:
		return
		
	# Swipe gesture recognition for speed boost (Left to Right)
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_pos[event.index] = event.position
			_touch_start_time[event.index] = Time.get_ticks_msec()
		else:
			_touch_start_pos.erase(event.index)
			_touch_start_time.erase(event.index)
			
	elif event is InputEventScreenDrag:
		if _touch_start_pos.has(event.index):
			var start_pos = _touch_start_pos[event.index]
			var diff = event.position - start_pos
			# Swipe from Left to Right: diff.x is positive, large enough, and diff.y is relatively horizontal
			if diff.x > 80.0 and abs(diff.y) < 100.0:
				if is_instance_valid(player):
					player._wants_to_speed = true
				# Clean up tracking for this touch event to avoid double-activation during the same swipe drag
				_touch_start_pos.erase(event.index)
				_touch_start_time.erase(event.index)

func _ready():
	add_to_group("in_game_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Clean up editor-designed UI nodes before constructing dynamic ones to avoid naming conflicts (queue_free)
	if has_node("HealthMargin"): $HealthMargin.queue_free()
	if has_node("ViewMapMargin"): $ViewMapMargin.queue_free()
	if has_node("HintMargin"): $HintMargin.queue_free()
	
	# Dynamically set background color modulation based on current level (every 10 levels gets a unique theme)
	var bg_rect = get_node_or_null("../Background/TextureRect")
	if bg_rect:
		bg_rect.modulate = get_tier_bg_color(GameManager.current_level)
	# Manage in-level BGM: play only if music is on and a valid stream is loaded
	if is_instance_valid(bgm):
		bgm.autoplay = false
		if SaveSystem.music_on and SaveSystem.music_volume > 0.01 and bgm.stream != null:
			bgm.volume_db = linear_to_db(SaveSystem.music_volume)
			bgm.play()
			# Loop the BGM when it finishes (only if music is still enabled)
			if not bgm.finished.is_connected(_on_bgm_finished):
				bgm.finished.connect(_on_bgm_finished)
		else:
			bgm.stop()
	
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
		
		# Start in MAP view (zoomed out)
		level_camera.zoom = map_zoom
		level_camera.global_position = level_center_pos
	
	# Setup Ruby Panel
	var ruby_panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	var ruby_hbox = HBoxContainer.new()
	ruby_hbox.add_theme_constant_override("separation", 10)
	
	var ruby_icon = TextureRect.new()
	ruby_icon.texture = ResourceManager.get_texture("res://assets/ruby.png")
	ruby_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ruby_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruby_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ruby_icon.custom_minimum_size = Vector2(30, 30)
	
	ruby_label = Label.new()
	ruby_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	ruby_label.add_theme_font_size_override("font_size", 32)
	ruby_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	ruby_label.add_theme_constant_override("outline_size", 5)
	
	ruby_hbox.add_child(ruby_icon)
	ruby_hbox.add_child(ruby_label)
	ruby_panel.add_child(ruby_hbox)
	
	var ruby_margin = MarginContainer.new()
	ruby_margin.add_theme_constant_override("margin_left", 20)
	ruby_margin.add_theme_constant_override("margin_top", 20)
	ruby_margin.add_child(ruby_panel)
	add_child(ruby_margin)
	
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
	
	# Setup Top Right Buttons (Map & Pause)
	var top_right_hbox = HBoxContainer.new()
	top_right_hbox.add_theme_constant_override("separation", 15)
	
	view_map_btn = UIFactory.create_glass_button("map", UIFactory.BLUE_COLOR)
	view_map_btn.focus_mode = Control.FOCUS_NONE
	view_map_btn.pressed.connect(_on_view_map_pressed)
	top_right_hbox.add_child(view_map_btn)
	
	var pause_btn = UIFactory.create_glass_button("pause", UIFactory.GOLD_COLOR)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(func():
		toggle_pause()
	)
	top_right_hbox.add_child(pause_btn)
	
	var map_margin = MarginContainer.new()
	map_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	map_margin.add_theme_constant_override("margin_top", 20)
	map_margin.add_theme_constant_override("margin_right", 40)
	map_margin.add_child(top_right_hbox)
	add_child(map_margin)
	
	# Setup Hint Button (available in all modes)
	hint_button = UIFactory.create_glass_button("hint", UIFactory.GOLD_COLOR)
	hint_button.focus_mode = Control.FOCUS_NONE
	hint_button.pressed.connect(_on_hint_pressed)
	
	var hint_margin = MarginContainer.new()
	hint_margin.name = "HintMargin"
	hint_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint_margin.add_theme_constant_override("margin_bottom", 20)
	hint_margin.add_theme_constant_override("margin_right", 40)
	hint_margin.add_child(hint_button)
	add_child(hint_margin)
	
	# Setup Level Indicator
	if not GameManager.is_endless_mode:
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
	
	# Setup Glide Assist Button
	if SaveSystem.glide_count > 0 or GameManager.is_endless_mode:
		var glide_txt = "glide" if GameManager.is_endless_mode else ("glide x%d" % SaveSystem.glide_count)
		glide_button = UIFactory.create_glass_button(glide_txt, Color(0.2, 0.6, 1.0))
		glide_button.focus_mode = Control.FOCUS_NONE
		glide_button.pressed.connect(_on_glide_pressed)
		
		var glide_margin = MarginContainer.new()
		glide_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glide_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		glide_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		glide_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
		glide_margin.add_theme_constant_override("margin_bottom", 80)
		glide_margin.add_theme_constant_override("margin_right", 40)
		glide_margin.add_child(glide_button)
		add_child(glide_margin)
		
		if is_instance_valid(player):
			player.glide_used.connect(_on_player_glide_used)
	
	# Setup Speed Assist Button (only if has speed charges)
	if SaveSystem.speed_count > 0:
		speed_button = UIFactory.create_glass_button("speed x%d" % SaveSystem.speed_count, Color(1.0, 0.4, 0.2))
		speed_button.focus_mode = Control.FOCUS_NONE
		speed_button.pressed.connect(_on_speed_pressed)
		
		var speed_margin = MarginContainer.new()
		speed_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		speed_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		speed_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		speed_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
		speed_margin.add_theme_constant_override("margin_bottom", 200)
		speed_margin.add_theme_constant_override("margin_right", 40)
		speed_margin.add_child(speed_button)
		add_child(speed_margin)
		
		if is_instance_valid(player):
			player.speed_used.connect(_on_player_speed_used)
	

	
	# Remove old UI
	if has_node("MarginContainer"): $MarginContainer.queue_free()
	
	# Left screen: Speed Zone
	var speed_zone = Control.new()
	speed_zone.name = "SpeedZone"
	speed_zone.anchor_left = 0.0
	speed_zone.anchor_top = 0.0
	speed_zone.anchor_right = 0.5
	speed_zone.anchor_bottom = 1.0
	speed_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	speed_zone.gui_input.connect(_on_speed_zone_gui_input)
	add_child(speed_zone)
	move_child(speed_zone, 0)

	# Right screen: Jump/Release Zone
	var jump_zone = Control.new()
	jump_zone.name = "JumpZone"
	jump_zone.anchor_left = 0.5
	jump_zone.anchor_top = 0.0
	jump_zone.anchor_right = 1.0
	jump_zone.anchor_bottom = 1.0
	jump_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	jump_zone.gui_input.connect(_on_jump_zone_gui_input)
	add_child(jump_zone)
	move_child(jump_zone, 1)
	

	

	
	# Auto-start with Map View and run countdown immediately
	is_viewing_map = true
	start_countdown()

func _process(delta: float):
	if is_instance_valid(health_label):
		health_label.text = "box health: %d%%" % int(GameManager.box_health)
	if is_instance_valid(ruby_label):
		ruby_label.text = "ruby: %d" % GameManager.current_rubies
	
	# Disable hint button when in zero gravity
	if is_instance_valid(hint_button) and not hint_used:
		if is_instance_valid(player) and player.current_planet != null:
			hint_button.disabled = false
			hint_button.modulate.a = 1.0
		else:
			hint_button.disabled = true
			hint_button.modulate.a = 0.3
			
	# Update glide button state
	if is_instance_valid(glide_button):
		if is_instance_valid(player):
			if SaveSystem.glide_count <= 0:
				# No glides left at all
				glide_button.text = "glide x0"
				glide_button.disabled = true
				glide_button.modulate.a = 0.3
			elif player.current_planet != null:
				# On a planet
				glide_button.text = "glide x%d" % SaveSystem.glide_count
				glide_button.disabled = true
				glide_button.modulate.a = 0.3
			elif player._tether_planet != null:
				# Currently gliding (keep enabled to allow multiple spend/redirects)
				glide_button.text = "glide x%d" % SaveSystem.glide_count
				glide_button.disabled = false
				glide_button.modulate.a = 1.0
			else:
				# In zero gravity with glides available and not currently active
				glide_button.text = "glide x%d" % SaveSystem.glide_count
				glide_button.disabled = false
				glide_button.modulate.a = 1.0

	# Update speed button state
	if is_instance_valid(speed_button):
		if is_instance_valid(player):
			if SaveSystem.speed_count <= 0:
				speed_button.text = "speed x0"
				speed_button.disabled = true
				speed_button.modulate.a = 0.3
			elif player.current_planet != null:
				speed_button.text = "speed x%d" % SaveSystem.speed_count
				speed_button.disabled = true
				speed_button.modulate.a = 0.3
			else:
				speed_button.text = "speed x%d" % SaveSystem.speed_count
				speed_button.disabled = false
				speed_button.modulate.a = 1.0
	
	# Disable buttons during countdown
	if not GameManager.is_gameplay_started:
		if is_instance_valid(hint_button):
			hint_button.disabled = true
			hint_button.modulate.a = 0.3
		if is_instance_valid(glide_button):
			glide_button.disabled = true
			glide_button.modulate.a = 0.3
		if is_instance_valid(speed_button):
			speed_button.disabled = true
			speed_button.modulate.a = 0.3
	
	if is_instance_valid(level_camera):
		var base_pos = level_camera.global_position
		if is_viewing_map:
			if GameManager.is_endless_mode and is_instance_valid(player):
				level_center_pos = player.global_position + Vector2(400, 0)
			# Zoom out to show level overview
			level_camera.zoom = level_camera.zoom.lerp(map_zoom, 5.0 * delta)
			base_pos = level_camera.global_position.lerp(level_center_pos, 8.0 * delta)
		else:
			# Zoom in to follow player
			level_camera.zoom = level_camera.zoom.lerp(default_zoom, 8.0 * delta)
			if is_instance_valid(player):
				# Use a fixed world-space offset so the camera doesn't fly off at low zoom
				var look_ahead := 200.0
				
				var target_x: float
				var target_y: float
				
				if is_instance_valid(player.current_planet):
					# While riding a planet, lock the camera to the planet so the screen doesn't spin.
					# Add a small horizontal offset so the planet sits left-of-center.
					target_x = player.current_planet.global_position.x + look_ahead
					target_y = player.current_planet.global_position.y
				else:
					# While jumping, follow the player through space with the same offset.
					target_x = player.global_position.x + look_ahead
					target_y = player.global_position.y
					
				var target = Vector2(target_x, target_y)
				base_pos = level_camera.global_position.lerp(target, 8.0 * delta)
				
		if shake_duration > 0.0:
			shake_duration -= delta
			var offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			level_camera.global_position = base_pos + offset
		else:
			level_camera.global_position = base_pos

func _on_hint_pressed():
	if hint_used:
		return
	# Only allow hint while riding a planet
	if not is_instance_valid(player) or player.current_planet == null:
		return
	hint_used = true
	if is_instance_valid(player):
		player.show_trajectory = true
		player.has_jumped = false # Prevent instant cancel if activated mid-air while falling onto a planet
	# Fade out the button after activation
	var tween = create_tween()
	tween.tween_property(hint_button, "modulate:a", 0.3, 0.5)
	hint_button.disabled = true

func _on_view_map_pressed():
	is_viewing_map = !is_viewing_map

func _on_glide_pressed():
	if is_instance_valid(player) and player.current_planet == null:
		if GameManager.is_endless_mode or SaveSystem.glide_count > 0:
			player._wants_to_jump = true

func _on_player_glide_used():
	if is_instance_valid(glide_button):
		if GameManager.is_endless_mode:
			glide_button.text = "glide"
			glide_button.disabled = false
			glide_button.modulate.a = 1.0
		else:
			glide_button.text = "glide x%d" % SaveSystem.glide_count
			if SaveSystem.glide_count > 0:
				glide_button.disabled = false
				glide_button.modulate.a = 1.0
			else:
				glide_button.disabled = true
				glide_button.modulate.a = 0.3

func _on_speed_pressed():
	if is_instance_valid(player) and player.current_planet == null and SaveSystem.speed_count > 0:
		player._wants_to_speed = true

func _on_player_speed_used():
	if is_instance_valid(speed_button):
		speed_button.text = "speed x%d" % SaveSystem.speed_count
		if SaveSystem.speed_count > 0:
			speed_button.disabled = false
			speed_button.modulate.a = 1.0
		else:
			speed_button.disabled = true
			speed_button.modulate.a = 0.3

func _on_jump_zone_gui_input(event: InputEvent):
	if not is_instance_valid(player):
		return
	if not GameManager.is_gameplay_started:
		return
	if event is InputEventScreenTouch and event.pressed:
		player._wants_to_jump = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		player._wants_to_jump = true

func _on_speed_zone_gui_input(event: InputEvent):
	if not is_instance_valid(player):
		return
	if not GameManager.is_gameplay_started:
		return
	if event is InputEventScreenTouch and event.pressed:
		player._wants_to_speed = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		player._wants_to_speed = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START and event.pressed):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if not GameManager.is_gameplay_started:
			return
		if event.keycode == KEY_M:
			_on_view_map_pressed()
		elif event.keycode == KEY_H:
			_on_hint_pressed()
	elif event is InputEventJoypadButton and event.pressed:
		if not GameManager.is_gameplay_started:
			return
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER or event.button_index == JOY_BUTTON_RIGHT_STICK:
			_on_view_map_pressed()
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_on_hint_pressed()
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT:
		if not GameManager.is_gameplay_started:
			return
		if event.axis_value > 0.5:
			if not _trigger_map_pressed:
				_trigger_map_pressed = true
				_on_view_map_pressed()
		else:
			_trigger_map_pressed = false

func toggle_pause():
	if is_instance_valid(player) and player.is_game_over:
		return
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		_create_pause_menu()
	else:
		if is_instance_valid(pause_overlay):
			pause_overlay.queue_free()
			pause_overlay = null

func _create_pause_menu():
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.02, 0.02, 0.12, 0.8)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_overlay)
	
	var panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	pause_overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "paused"
	title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var resume_btn = UIFactory.create_glass_button("resume", UIFactory.GOLD_COLOR)
	resume_btn.pressed.connect(func():
		toggle_pause()
	)
	vbox.add_child(resume_btn)
	
	var retry_btn = UIFactory.create_glass_button("retry", UIFactory.GOLD_COLOR)
	retry_btn.pressed.connect(func():
		toggle_pause()
		GameManager.reset_rubies()
		SceneTransition.reload_current()
	)
	vbox.add_child(retry_btn)
	
	var menu_btn_label = "main menu" if GameManager.is_endless_mode else "levels"
	var levels_btn = UIFactory.create_glass_button(menu_btn_label, UIFactory.GOLD_COLOR)
	levels_btn.pressed.connect(func():
		toggle_pause()
		if GameManager.is_endless_mode:
			GameManager.is_endless_mode = false
			SceneTransition.transition_to("res://scenes/menu.tscn")
		else:
			SceneTransition.transition_to("res://scenes/level_select.tscn")
	)
	vbox.add_child(levels_btn)
	
	# Music Section
	var music_label = Label.new()
	music_label.text = "music: %d%%" % int(SaveSystem.music_volume * 100)
	music_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	music_label.add_theme_font_size_override("font_size", 24)
	music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	vbox.add_child(music_label)
	
	var music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = SaveSystem.music_volume
	music_slider.focus_mode = Control.FOCUS_ALL
	music_slider.custom_minimum_size = Vector2(200, 0)
	music_slider.value_changed.connect(func(val):
		SaveSystem.music_volume = val
		SaveSystem.music_on = val > 0.01
		SaveSystem.save_data()
		music_label.text = "music: %d%%" % int(val * 100)
		if is_instance_valid(bgm):
			if val > 0.01:
				bgm.volume_db = linear_to_db(val)
				if not bgm.playing and bgm.stream != null:
					bgm.play()
			else:
				bgm.stop()
	)
	vbox.add_child(music_slider)
	
	# SFX Section
	var sfx_label = Label.new()
	sfx_label.text = "sfx: %d%%" % int(SaveSystem.sfx_volume * 100)
	sfx_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	sfx_label.add_theme_font_size_override("font_size", 24)
	sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sfx_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	vbox.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = SaveSystem.sfx_volume
	sfx_slider.focus_mode = Control.FOCUS_ALL
	sfx_slider.custom_minimum_size = Vector2(200, 0)
	sfx_slider.value_changed.connect(func(val):
		SaveSystem.sfx_volume = val
		SaveSystem.sfx_on = val > 0.01
		SaveSystem.save_data()
		sfx_label.text = "sfx: %d%%" % int(val * 100)
		SoundManager.update_looping_sfx_volumes()
		if val <= 0.01:
			SoundManager.stop_sfx_loop("thruster")
	)
	vbox.add_child(sfx_slider)
	
	var quit_btn = UIFactory.create_glass_button("quit to menu", UIFactory.RED_COLOR)
	quit_btn.pressed.connect(func():
		toggle_pause()
		SceneTransition.transition_to("res://scenes/menu.tscn")
	)
	vbox.add_child(quit_btn)

	resume_btn.focus_neighbor_bottom = retry_btn.get_path()
	resume_btn.focus_neighbor_top = quit_btn.get_path()
	
	retry_btn.focus_neighbor_bottom = levels_btn.get_path()
	retry_btn.focus_neighbor_top = resume_btn.get_path()
	
	levels_btn.focus_neighbor_bottom = music_slider.get_path()
	levels_btn.focus_neighbor_top = retry_btn.get_path()
	
	music_slider.focus_neighbor_bottom = sfx_slider.get_path()
	music_slider.focus_neighbor_top = levels_btn.get_path()
	
	sfx_slider.focus_neighbor_bottom = quit_btn.get_path()
	sfx_slider.focus_neighbor_top = music_slider.get_path()
	
	quit_btn.focus_neighbor_bottom = resume_btn.get_path()
	quit_btn.focus_neighbor_top = sfx_slider.get_path()
	
	resume_btn.grab_focus()

func _on_bgm_finished():
	# Only loop in-level BGM if music is still enabled
	if is_instance_valid(bgm) and SaveSystem.music_on and SaveSystem.music_volume > 0.01 and bgm.stream != null:
		bgm.volume_db = linear_to_db(SaveSystem.music_volume)
		bgm.play()

func shake_camera(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

func show_tutorial():
	print("[Tutorial] show_tutorial called! Pausing game tree.")
	get_tree().paused = true
	
	var tut_overlay = ColorRect.new()
	tut_overlay.name = "TutorialOverlay"
	tut_overlay.color = Color(0, 0, 0, 0.75)
	tut_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tut_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	tut_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(tut_overlay)
	
	var panel = UIFactory.create_glass_panel(UIFactory.BLUE_COLOR)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	tut_overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "how to deliver"
	title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var controls = [
		{"keys": "auto-drive", "desc": "your bike drives forward automatically on planets."},
		{"keys": "space / tap right screen", "desc": "launch into orbit or release tether gravity field."},
		{"keys": "left arrow or a / hold left screen", "desc": "slow down to avoid flying off planets too fast."},
		{"keys": "click glide button", "desc": "redirect velocity in outer space (buy glides in menu)."},
		{"keys": "reach portal", "desc": "deliver the fragile box to the portal with high health for 3 stars."}
	]
	
	for item in controls:
		var item_hbox = HBoxContainer.new()
		item_hbox.add_theme_constant_override("separation", 10)
		item_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var label_keys = Label.new()
		label_keys.text = "[%s]" % item["keys"]
		label_keys.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		label_keys.add_theme_font_size_override("font_size", 20)
		label_keys.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		label_keys.custom_minimum_size = Vector2(250, 0)
		item_hbox.add_child(label_keys)
		
		var label_desc = Label.new()
		label_desc.text = "— %s" % item["desc"]
		label_desc.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		label_desc.add_theme_font_size_override("font_size", 18)
		label_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label_desc.custom_minimum_size = Vector2(400, 0)
		item_hbox.add_child(label_desc)
		
		vbox.add_child(item_hbox)
		
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	var start_btn = UIFactory.create_glass_button("start delivery", UIFactory.GREEN_COLOR)
	start_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	start_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	start_btn.pressed.connect(func():
		print("[Tutorial] Start delivery button pressed! Resuming game and removing overlay.")
		get_tree().paused = false
		tut_overlay.queue_free()
	)
	vbox.add_child(start_btn)
	start_btn.grab_focus()
	
	# Auto-close tutorial after 10 seconds if player does not press start
	var auto_close_timer = get_tree().create_timer(10.0, true)
	auto_close_timer.timeout.connect(func():
		if is_instance_valid(tut_overlay):
			print("[Tutorial] 10-second auto-close timeout reached. Resuming game.")
			get_tree().paused = false
			tut_overlay.queue_free()
	)

func get_tier_bg_color(lvl: int) -> Color:
	if lvl >= 81:
		return Color(0.35, 0.3, 0.1, 1.0)      # 81-90: Gold/Yellow (Theme 9)
	elif lvl >= 71:
		return Color(0.45, 0.15, 0.15, 1.0)    # 71-80: Red/Rose (Theme 8)
	elif lvl >= 61:
		return Color(0.4, 0.15, 0.3, 1.0)      # 61-70: Magenta/Pink (Theme 7)
	elif lvl >= 51:
		return Color(0.1, 0.3, 0.45, 1.0)      # 51-60: Cyan/Sky Blue (Theme 6)
	elif lvl >= 41:
		return Color(0.4, 0.25, 0.1, 1.0)      # 41-50: Orange (Theme 5)
	elif lvl >= 31:
		return Color(0.15, 0.35, 0.2, 1.0)     # 31-40: Green (Theme 4)
	elif lvl >= 21:
		return Color(0.3, 0.15, 0.45, 1.0)     # 21-30: Purple (Theme 3)
	elif lvl >= 11:
		return Color(0.1, 0.35, 0.35, 1.0)     # 11-20: Teal/Cyan (Theme 2)
	else:
		return Color(0.15, 0.25, 0.45, 1.0)    # 1-10: Blue (Theme 1)

func start_countdown():
	# Create a countdown label in the center of the screen
	var countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	countdown_label.add_theme_font_size_override("font_size", 120)
	countdown_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	countdown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	countdown_label.add_theme_constant_override("outline_size", 20)
	
	# Position in the center of the viewport
	countdown_label.custom_minimum_size = Vector2(300, 150)
	countdown_label.set_anchors_preset(Control.PRESET_CENTER)
	countdown_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	countdown_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	countdown_label.pivot_offset = Vector2(150, 75)
	
	add_child(countdown_label)
	
	# Disable view map button during countdown
	if is_instance_valid(view_map_btn):
		view_map_btn.disabled = true
		view_map_btn.modulate.a = 0.3
		
	# If level 4, show the asteroid warning message
	var warning_panel = null
	var warning_margin = null
	if GameManager.current_level == 4:
		warning_panel = UIFactory.create_glass_panel(UIFactory.RED_COLOR)
		var warning_label = Label.new()
		warning_label.text = "from this level onwards u will get asteroid"
		warning_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		warning_label.add_theme_font_size_override("font_size", 24)
		warning_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning_panel.add_child(warning_label)
		
		warning_margin = MarginContainer.new()
		warning_margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		warning_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
		warning_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
		warning_margin.add_theme_constant_override("margin_bottom", 120)
		warning_margin.add_child(warning_panel)
		add_child(warning_margin)
		
	# Countdown sequence: 3 -> 2 -> 1 (while in full map view)
	var sequence = ["3", "2", "1"]
	for text in sequence:
		countdown_label.text = text
		SoundManager.play_sfx("jump") # tick sound
			
		# Animate the label scaling/fade for punchy arcade feel
		countdown_label.scale = Vector2(1.5, 1.5)
		var tween = create_tween()
		tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Wait 0.33 seconds (respecting pause mode since process always)
		await get_tree().create_timer(0.33, false).timeout
		
	# Zoom in to player (go to zoom)
	countdown_label.text = ""
	is_viewing_map = false
	
	# Wait for camera to complete zoom-in (0.4 seconds)
	await get_tree().create_timer(0.4, false).timeout
	
	# Enable controls and show go!
	GameManager.is_gameplay_started = true
	
	# Play "go!" sound and show "go!" animation
	SoundManager.play_sfx("tether") # high pitch go! sound
	countdown_label.text = "go!"
	countdown_label.scale = Vector2(1.6, 1.6)
	var tween = create_tween()
	tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(countdown_label, "modulate:a", 0.0, 0.4).set_delay(0.4)
	
	# Fade out warning panel if it exists
	if is_instance_valid(warning_panel):
		var warning_tween = create_tween()
		warning_tween.tween_property(warning_panel, "modulate:a", 0.0, 0.5)
	
	# Enable view map button
	if is_instance_valid(view_map_btn):
		view_map_btn.disabled = false
		view_map_btn.modulate.a = 1.0
		
	await get_tree().create_timer(0.8, false).timeout
	countdown_label.queue_free()
	if is_instance_valid(warning_margin):
		warning_margin.queue_free()

