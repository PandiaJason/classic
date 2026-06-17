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

var score_label: Label
var health_label: Label
var view_map_btn: Button
var hint_button: Button
var hint_used: bool = false
var map_timer = null
var glide_button: Button

var is_paused: bool = false
var pause_overlay: Control = null

var shake_intensity: float = 0.0
var shake_duration: float = 0.0

func _ready():
	add_to_group("in_game_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	
	# Setup Top Right Buttons (Map & Pause)
	var top_right_hbox = HBoxContainer.new()
	top_right_hbox.add_theme_constant_override("separation", 15)
	
	view_map_btn = UIFactory.create_glass_button("map", UIFactory.BLUE_COLOR)
	view_map_btn.pressed.connect(_on_view_map_pressed)
	top_right_hbox.add_child(view_map_btn)
	
	var pause_btn = UIFactory.create_glass_button("pause", UIFactory.GOLD_COLOR)
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
	
	# Setup Hint Button
	hint_button = UIFactory.create_glass_button("hint", UIFactory.GOLD_COLOR)
	hint_button.button_down.connect(_on_hint_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	
	var hint_margin = MarginContainer.new()
	hint_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	
	# Setup Glide Assist Button (only if has glides)
	if SaveSystem.glide_count > 0:
		glide_button = UIFactory.create_glass_button("glide x%d" % SaveSystem.glide_count, Color(0.2, 0.6, 1.0))
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
	

	
	# Remove old UI
	if has_node("MarginContainer"): $MarginContainer.queue_free()
	
	# Left Brake Zone (35% width)
	var brake_zone = Control.new()
	brake_zone.name = "BrakeZone"
	brake_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	brake_zone.anchor_right = 0.35
	brake_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	brake_zone.gui_input.connect(_on_brake_zone_gui_input)
	add_child(brake_zone)
	move_child(brake_zone, 0)
	
	if GameManager.current_level == 1:
		var brake_label = Label.new()
		brake_label.text = "brake"
		brake_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		brake_label.add_theme_font_size_override("font_size", 24)
		brake_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.12))
		brake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		brake_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		brake_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		brake_zone.add_child(brake_label)
	
	# Right Jump Zone (65% width)
	var jump_zone = Control.new()
	jump_zone.name = "JumpZone"
	jump_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	jump_zone.anchor_left = 0.35
	jump_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	jump_zone.gui_input.connect(_on_jump_zone_gui_input)
	add_child(jump_zone)
	move_child(jump_zone, 0)
	
	if GameManager.current_level == 1:
		var jump_label = Label.new()
		jump_label.text = "jump / glide"
		jump_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		jump_label.add_theme_font_size_override("font_size", 24)
		jump_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.12))
		jump_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jump_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		jump_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		jump_zone.add_child(jump_label)
	
	if has_node("HealthMargin"): $HealthMargin.queue_free()
	if has_node("ViewMapMargin"): $ViewMapMargin.queue_free()
	if has_node("HintMargin"): $HintMargin.queue_free()
	
	# Auto-start with Map View for 3 seconds, then focus on player
	is_viewing_map = true
	map_timer = get_tree().create_timer(3.0)
	map_timer.timeout.connect(func():
		is_viewing_map = false
		if is_instance_valid(level_camera) and is_instance_valid(player):
			level_camera.global_position = player.global_position
			level_camera.zoom = default_zoom
		if GameManager.current_level == 1 and not SaveSystem.tutorial_complete:
			SaveSystem.tutorial_complete = true
			SaveSystem.save_data()
			show_tutorial()
	)

func _process(delta: float):
	if is_instance_valid(health_label):
		health_label.text = "box health: %d%%" % int(GameManager.box_health)
	if is_instance_valid(score_label):
		score_label.text = "score: %d" % GameManager.current_score
	
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
	
	if is_instance_valid(level_camera):
		var base_pos = level_camera.global_position
		if is_viewing_map:
			# Zoom out to show full level
			level_camera.zoom = level_camera.zoom.lerp(map_zoom, 5.0 * delta)
			base_pos = level_camera.global_position.lerp(level_center_pos, 8.0 * delta)
		else:
			# Zoom in to follow player
			level_camera.zoom = level_camera.zoom.lerp(default_zoom, 5.0 * delta)
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
				base_pos = level_camera.global_position.lerp(target, 6.0 * delta)
				
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
	if is_instance_valid(player) and player.current_planet == null and SaveSystem.glide_count > 0:
		player._wants_to_jump = true

func _on_player_glide_used():
	if is_instance_valid(glide_button):
		glide_button.text = "glide x%d" % SaveSystem.glide_count
		if SaveSystem.glide_count > 0:
			glide_button.disabled = false
			glide_button.modulate.a = 1.0
		else:
			glide_button.disabled = true
			glide_button.modulate.a = 0.3

func _on_jump_zone_gui_input(event: InputEvent):
	if not is_instance_valid(player):
		return
	if event is InputEventScreenTouch and event.pressed:
		player._wants_to_jump = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		player._wants_to_jump = true

func _on_brake_zone_gui_input(event: InputEvent):
	if not is_instance_valid(player):
		return
	if event is InputEventScreenTouch:
		player._wants_to_brake = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		player._wants_to_brake = event.pressed



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_on_view_map_pressed()
		elif event.keycode == KEY_H:
			_on_hint_pressed()

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
		GameManager.reset_score()
		SceneTransition.reload_current()
	)
	vbox.add_child(retry_btn)
	
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
	music_slider.focus_mode = Control.FOCUS_NONE
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
	sfx_slider.focus_mode = Control.FOCUS_NONE
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
	
	# Auto-close tutorial after 10 seconds if player does not press start
	var auto_close_timer = get_tree().create_timer(10.0, true)
	auto_close_timer.timeout.connect(func():
		if is_instance_valid(tut_overlay):
			print("[Tutorial] 10-second auto-close timeout reached. Resuming game.")
			get_tree().paused = false
			tut_overlay.queue_free()
	)
