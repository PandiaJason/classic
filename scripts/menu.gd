extends Control

const GAME_FONT = preload("res://assets/game_font.ttf")

var _ruby_btn: TextureButton = null
var _pulse_time: float = 0.0
var _ruby_label: Label = null
var tutorial_btn: Button = null
var achievements_btn: Button = null
var reset_btn: Button = null
var daily_btn: Button = null
var start_btn: Button = null
var music_slider: HSlider = null
var sfx_slider: HSlider = null

func _ready():
	BgmManager.play_menu_music()
	# Group buttons inside a VBox for tight vertical stacking
	var button_vbox = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 12)
	button_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	start_btn = $VBoxContainer/StartButton
	$VBoxContainer.remove_child(start_btn)
	button_vbox.add_child(start_btn)
	start_btn.pressed.connect(_on_start_pressed)
	
	tutorial_btn = UIFactory.create_glass_button("tutorial", UIFactory.BLUE_COLOR)
	tutorial_btn.add_theme_font_size_override("font_size", 20)
	tutorial_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	button_vbox.add_child(tutorial_btn)
	
	achievements_btn = UIFactory.create_glass_button("achievements  %d/%d" % [AchievementManager.get_unlocked_count(), AchievementManager.get_total_count()], UIFactory.GOLD_COLOR)
	achievements_btn.add_theme_font_size_override("font_size", 20)
	achievements_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	achievements_btn.pressed.connect(_on_achievements_pressed)
	button_vbox.add_child(achievements_btn)
	
	if SaveSystem.unlocked_levels > 90:
		var ruby_btn = TextureButton.new()
		ruby_btn.texture_normal = ResourceManager.get_texture("res://assets/ruby.png")
		ruby_btn.ignore_texture_size = true
		ruby_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		ruby_btn.custom_minimum_size = Vector2(48, 48)
		ruby_btn.tooltip_text = "view credits"
		ruby_btn.pressed.connect(func():
			SceneTransition.transition_to("res://scenes/credits.tscn")
		)
		var title_lbl = $VBoxContainer/TitleLabel
		title_lbl.add_child(ruby_btn)
		_ruby_btn = ruby_btn
	
	$VBoxContainer.add_child(button_vbox)
	
	# Use UIFactory for central panels
	var ruby_panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var ruby_icon = TextureRect.new()
	ruby_icon.texture = ResourceManager.get_texture("res://assets/ruby.png")
	ruby_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruby_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ruby_icon.custom_minimum_size = Vector2(40, 40)
	
	var ruby_label = Label.new()
	ruby_label.text = "ruby: " + str(SaveSystem.global_rubies)
	_ruby_label = ruby_label
	ruby_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	ruby_label.add_theme_font_size_override("font_size", 30)
	ruby_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	ruby_label.add_theme_color_override("font_outline_color", Color.BLACK)
	ruby_label.add_theme_constant_override("outline_size", 8)
	
	hbox.add_child(ruby_icon)
	hbox.add_child(ruby_label)
	ruby_panel.add_child(hbox)
	
	var ruby_margin = MarginContainer.new()
	ruby_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	ruby_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ruby_margin.add_theme_constant_override("margin_top", 30)
	ruby_margin.add_theme_constant_override("margin_right", 30)
	ruby_margin.add_child(ruby_panel)
	add_child(ruby_margin)
	
	# Top Center Endless Mode Button
	var top_endless_title = "endless mode"
	if SaveSystem.endless_high_score > 0:
		top_endless_title += " (%dm)" % SaveSystem.endless_high_score
	var top_endless_btn = UIFactory.create_glass_button(top_endless_title, UIFactory.PURPLE_COLOR)
	top_endless_btn.add_theme_font_size_override("font_size", 22)
	top_endless_btn.pressed.connect(_on_endless_pressed)
	
	var top_endless_margin = MarginContainer.new()
	top_endless_margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	top_endless_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top_endless_margin.add_theme_constant_override("margin_top", 30)
	top_endless_margin.add_child(top_endless_btn)
	add_child(top_endless_margin)
	
	# Unmute Master bus to ensure sound effects always work
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_idx, false)
	
	# Music and SFX Volume Sliders using UIFactory
	var audio_panel = UIFactory.create_glass_panel(UIFactory.BLUE_COLOR)
	
	var audio_vbox = VBoxContainer.new()
	audio_vbox.add_theme_constant_override("separation", 6)
	audio_vbox.custom_minimum_size = Vector2(250, 0)
	
	# Music Section
	var music_label = Label.new()
	music_label.text = "music: %d%%" % int(SaveSystem.music_volume * 100)
	music_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	music_label.add_theme_font_size_override("font_size", 22)
	music_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	audio_vbox.add_child(music_label)
	
	music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = SaveSystem.music_volume
	music_slider.focus_mode = Control.FOCUS_ALL
	music_slider.value_changed.connect(func(val):
		SaveSystem.music_volume = val
		SaveSystem.music_on = val > 0.01
		SaveSystem.save_data()
		music_label.text = "music: %d%%" % int(val * 100)
		BgmManager.update_volume()
	)
	audio_vbox.add_child(music_slider)
	
	# Space spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	audio_vbox.add_child(spacer)
	
	# SFX Section
	var sfx_label = Label.new()
	sfx_label.text = "sfx: %d%%" % int(SaveSystem.sfx_volume * 100)
	sfx_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	sfx_label.add_theme_font_size_override("font_size", 22)
	sfx_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	audio_vbox.add_child(sfx_label)
	
	sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = SaveSystem.sfx_volume
	sfx_slider.focus_mode = Control.FOCUS_ALL
	sfx_slider.value_changed.connect(func(val):
		SaveSystem.sfx_volume = val
		SaveSystem.sfx_on = val > 0.01
		SaveSystem.save_data()
		sfx_label.text = "sfx: %d%%" % int(val * 100)
		SoundManager.update_looping_sfx_volumes()
	)
	audio_vbox.add_child(sfx_slider)
	
	audio_panel.add_child(audio_vbox)
	
	var audio_margin = MarginContainer.new()
	audio_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	audio_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	audio_margin.add_theme_constant_override("margin_bottom", 30)
	audio_margin.add_theme_constant_override("margin_left", 30)
	audio_margin.add_child(audio_panel)
	add_child(audio_margin)
	
	# Calculate and Display Delivery Rate
	var unlocked_count = 0
	var total_stars = 0
	for i in range(1, 91):
		if SaveSystem.is_level_unlocked(i):
			unlocked_count += 1
			total_stars += SaveSystem.get_stars(i)

	var delivery_rate = 0.0
	if unlocked_count > 0:
		delivery_rate = float(total_stars) / float(unlocked_count * 3.0)
		
	var rate_panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	var rate_hbox = HBoxContainer.new()
	rate_hbox.add_theme_constant_override("separation", 10)
	rate_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var delivery_icon = TextureRect.new()
	delivery_icon.texture = ResourceManager.get_texture("res://assets/delivery_box.png")
	delivery_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	delivery_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	delivery_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	delivery_icon.custom_minimum_size = Vector2(76, 40)
	
	var rate_label = Label.new()
	rate_label.text = "delivery rate: %.2f" % delivery_rate
	rate_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	rate_label.add_theme_font_size_override("font_size", 30)
	rate_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	rate_label.add_theme_constant_override("outline_size", 8)
	
	rate_hbox.add_child(delivery_icon)
	rate_hbox.add_child(rate_label)
	rate_panel.add_child(rate_hbox)
	
	var rate_margin = MarginContainer.new()
	rate_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	rate_margin.add_theme_constant_override("margin_top", 30)
	rate_margin.add_theme_constant_override("margin_left", 30)
	rate_margin.add_child(rate_panel)
	add_child(rate_margin)

	if SaveSystem.unlocked_levels > 90:
		# Reset Button using UIFactory (Red Style)
		reset_btn = UIFactory.create_glass_button("reset", UIFactory.RED_COLOR)
		var reset_margin = MarginContainer.new()
		reset_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		reset_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		reset_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
		reset_margin.add_theme_constant_override("margin_bottom", 30)
		reset_margin.add_theme_constant_override("margin_right", 30)
		reset_margin.add_child(reset_btn)
		add_child(reset_margin)

		reset_btn.pressed.connect(_on_reset_pressed)

	# Copyright notice (bottom center)
	var copyright = Label.new()
	copyright.text = "copyright by hikki studios"
	copyright.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	copyright.add_theme_font_size_override("font_size", 18)
	copyright.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 0.6))
	copyright.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var copy_margin = MarginContainer.new()
	copy_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	copy_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	copy_margin.add_theme_constant_override("margin_bottom", 8)
	copy_margin.add_child(copyright)
	add_child(copy_margin)
	
	# Setup Daily Reward button on the top left, below rate panel
	daily_btn = UIFactory.create_glass_button("daily reward", UIFactory.GOLD_COLOR)
	daily_btn.add_theme_font_size_override("font_size", 20)
	daily_btn.pressed.connect(func():
		_show_daily_rewards_popup()
	)
	
	var daily_margin = MarginContainer.new()
	daily_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	daily_margin.add_theme_constant_override("margin_top", 110)
	daily_margin.add_theme_constant_override("margin_left", 30)
	daily_margin.add_child(daily_btn)
	add_child(daily_margin)
	
	# Focus Networking for controllers
	start_btn.focus_neighbor_top = daily_btn.get_path()
	start_btn.focus_neighbor_bottom = tutorial_btn.get_path()
	start_btn.focus_neighbor_left = daily_btn.get_path()
	
	tutorial_btn.focus_neighbor_top = start_btn.get_path()
	tutorial_btn.focus_neighbor_bottom = achievements_btn.get_path()
	
	achievements_btn.focus_neighbor_top = tutorial_btn.get_path()
	achievements_btn.focus_neighbor_bottom = music_slider.get_path()
	
	daily_btn.focus_neighbor_right = start_btn.get_path()
	daily_btn.focus_neighbor_bottom = start_btn.get_path()
	
	music_slider.focus_neighbor_top = achievements_btn.get_path()
	music_slider.focus_neighbor_bottom = sfx_slider.get_path()
	music_slider.focus_neighbor_right = reset_btn.get_path() if reset_btn else achievements_btn.get_path()
	
	sfx_slider.focus_neighbor_top = music_slider.get_path()
	sfx_slider.focus_neighbor_right = reset_btn.get_path() if reset_btn else achievements_btn.get_path()
	
	if reset_btn:
		reset_btn.focus_neighbor_left = sfx_slider.get_path()
		reset_btn.focus_neighbor_top = achievements_btn.get_path()
		achievements_btn.focus_neighbor_right = reset_btn.get_path()
		start_btn.focus_neighbor_right = reset_btn.get_path()
		
	if is_instance_valid(_ruby_btn):
		_ruby_btn.focus_mode = Control.FOCUS_ALL
		_ruby_btn.focus_neighbor_bottom = start_btn.get_path()
		start_btn.focus_neighbor_top = _ruby_btn.get_path()
		daily_btn.focus_neighbor_right = _ruby_btn.get_path()
		_ruby_btn.focus_neighbor_left = daily_btn.get_path()
	
	# Auto-open daily reward if available
	if SaveSystem.is_daily_reward_available():
		get_tree().create_timer(0.2).timeout.connect(func():
			_show_daily_rewards_popup()
		)
	else:
		start_btn.grab_focus()



func _on_endless_pressed():
	if OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	GameManager.start_endless_mode()

func _on_start_pressed():
	if OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	SceneTransition.transition_to("res://scenes/level_select.tscn")

func _on_tutorial_pressed():
	_set_main_menu_buttons_focusable(false)
	var tut_overlay = ColorRect.new()
	tut_overlay.name = "TutorialOverlay"
	tut_overlay.color = Color(0, 0, 0, 0.8)
	tut_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tut_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(tut_overlay)
	
	var panel = UIFactory.create_glass_panel(UIFactory.BLUE_COLOR)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	tut_overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
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
		{"icon": "res://assets/planet_1.png", "keys": "auto-drive", "desc": "your bike drives forward automatically on planets."},
		{"icon": "res://assets/custom_player.png", "keys": "space / tap right screen", "desc": "launch into orbit or release tether gravity field."},
		{"icon": "res://assets/custom_player.png", "keys": "click glide button", "desc": "redirect velocity in outer space (buy glides in menu)."},
		{"icon": "res://assets/custom_player.png", "keys": "shift / tap left screen", "desc": "speed up outer space flying (buy speed boosts in menu)."},
		{"icon": "res://assets/ruby.png", "keys": "space rubies", "desc": "collect glowing rubies around levels to increase ruby."},
		{"icon": "res://assets/asteroid.png", "keys": "asteroids", "desc": "avoid fast-moving space rocks that damage your cargo."},
		{"icon": "res://assets/flag.png", "keys": "reach portal", "desc": "deliver the fragile box to the portal with high health."}
	]
	
	for item in controls:
		var item_hbox = HBoxContainer.new()
		item_hbox.add_theme_constant_override("separation", 15)
		item_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Asset Icon
		var icon_rect = TextureRect.new()
		icon_rect.texture = ResourceManager.get_texture(item["icon"])
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(40, 40)
		item_hbox.add_child(icon_rect)
		
		# Key bindings
		var label_keys = Label.new()
		label_keys.text = "[%s]" % item["keys"]
		label_keys.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		label_keys.add_theme_font_size_override("font_size", 20)
		label_keys.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		label_keys.custom_minimum_size = Vector2(240, 0)
		item_hbox.add_child(label_keys)
		
		# Description
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
	
	var close_btn = UIFactory.create_glass_button("close", UIFactory.RED_COLOR)
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.pressed.connect(func():
		_set_main_menu_buttons_focusable(true)
		tut_overlay.queue_free()
		if is_instance_valid(tutorial_btn):
			tutorial_btn.grab_focus()
	)
	
	vbox.add_child(close_btn)
	
	# Trap focus neighborhood (directional keys)
	close_btn.focus_neighbor_left = close_btn.get_path()
	close_btn.focus_neighbor_right = close_btn.get_path()
	close_btn.focus_neighbor_top = close_btn.get_path()
	close_btn.focus_neighbor_bottom = close_btn.get_path()
	
	# Trap focus loop (Tab/Shift+Tab keys)
	close_btn.focus_next = close_btn.get_path()
	close_btn.focus_previous = close_btn.get_path()
	
	close_btn.grab_focus()

func _on_reset_pressed():
	_set_main_menu_buttons_focusable(false)
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var dialog = UIFactory.create_glass_panel(UIFactory.RED_COLOR)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialog.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(dialog)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var warn_title = Label.new()
	warn_title.text = "⚠ reset game?"
	warn_title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	warn_title.add_theme_font_size_override("font_size", 44)
	warn_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	warn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warn_title)

	var warn_msg = Label.new()
	warn_msg.text = "all progress, stars and ruby\nwill be permanently deleted!"
	warn_msg.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	warn_msg.add_theme_font_size_override("font_size", 28)
	warn_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warn_msg)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var cancel_btn = UIFactory.create_glass_button("cancel", UIFactory.BLUE_COLOR)
	cancel_btn.pressed.connect(func():
		_set_main_menu_buttons_focusable(true)
		overlay.queue_free()
		dialog.queue_free()
		if is_instance_valid(reset_btn):
			reset_btn.grab_focus()
	)

	var confirm_btn = UIFactory.create_glass_button("yes, reset!", UIFactory.RED_COLOR)
	confirm_btn.pressed.connect(func():
		SaveSystem.unlocked_levels = 1
		SaveSystem.global_rubies = 0
		SaveSystem.glide_count = 0
		for i in range(1, 91):
			SaveSystem.level_stars[i] = 0
		SaveSystem.save_data()
		SceneTransition.reload_current()
	)

	btn_row.add_child(cancel_btn)
	btn_row.add_child(confirm_btn)
	vbox.add_child(btn_row)
	dialog.add_child(vbox)
	
	cancel_btn.focus_neighbor_left = confirm_btn.get_path()
	cancel_btn.focus_neighbor_right = confirm_btn.get_path()
	cancel_btn.focus_neighbor_top = cancel_btn.get_path()
	cancel_btn.focus_neighbor_bottom = cancel_btn.get_path()
	
	confirm_btn.focus_neighbor_left = cancel_btn.get_path()
	confirm_btn.focus_neighbor_right = cancel_btn.get_path()
	confirm_btn.focus_neighbor_top = confirm_btn.get_path()
	confirm_btn.focus_neighbor_bottom = confirm_btn.get_path()
	
	# Trap Tab focus loop
	cancel_btn.focus_next = confirm_btn.get_path()
	cancel_btn.focus_previous = confirm_btn.get_path()
	confirm_btn.focus_next = cancel_btn.get_path()
	confirm_btn.focus_previous = cancel_btn.get_path()
	
	cancel_btn.grab_focus()

func _process(delta: float):
	if has_node("BackgroundAction"):
		var bg_action = $BackgroundAction
		var vp_size = get_viewport_rect().size
		bg_action.position = vp_size / 2.0 - Vector2(640, 360)

	if is_instance_valid(_ruby_btn):
		_pulse_time += delta * 4.0
		var pulse_scale = 1.0 + sin(_pulse_time) * 0.12
		_ruby_btn.scale = Vector2(pulse_scale, pulse_scale)
		_ruby_btn.pivot_offset = _ruby_btn.custom_minimum_size / 2.0
		
		# Keep it centered above the title text
		var title_lbl = $VBoxContainer/TitleLabel
		_ruby_btn.position.x = (title_lbl.size.x - _ruby_btn.custom_minimum_size.x) / 2.0
		_ruby_btn.position.y = -60.0
		
		var brightness = 1.0 + (sin(_pulse_time) + 1.0) * 0.2
		_ruby_btn.modulate = Color(brightness, brightness, brightness, 1.0)

func _show_daily_rewards_popup():
	_set_main_menu_buttons_focusable(false)
	# Create overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	# Create center container inside overlay
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(center)
	
	# Create dialog
	var dialog = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	style.corner_radius_top_left = 25
	style.corner_radius_top_right = 25
	style.corner_radius_bottom_right = 25
	style.corner_radius_bottom_left = 25
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 0.8, 0.2, 0.8) # Gold border
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	dialog.add_theme_stylebox_override("panel", style)
	center.add_child(dialog)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Title
	var title = Label.new()
	title.text = "daily streak rewards"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(title)
	
	# Subtitle/Description
	var subtitle = Label.new()
	subtitle.text = "play consecutive days to earn rubies! miss a day and it restarts lol."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(subtitle)
	
	# HBox for the 7 days
	var cards_hbox = HBoxContainer.new()
	cards_hbox.add_theme_constant_override("separation", 12)
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var current_streak = SaveSystem.streak_count
	var last_claim = SaveSystem.last_claim_day
	var claim_avail = SaveSystem.is_daily_reward_available()
	var today_candidate = SaveSystem.get_next_streak_day()
	
	for day in range(1, 8):
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(110, 160)
		
		var card_style = StyleBoxFlat.new()
		card_style.corner_radius_top_left = 15
		card_style.corner_radius_top_right = 15
		card_style.corner_radius_bottom_right = 15
		card_style.corner_radius_bottom_left = 15
		card_style.border_width_left = 2
		card_style.border_width_top = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
		
		var is_claimed = false
		var is_today = false
		var is_locked = false
		
		if claim_avail:
			if day < today_candidate:
				is_claimed = true
			elif day == today_candidate:
				is_today = true
			else:
				is_locked = true
		else:
			if day <= current_streak:
				is_claimed = true
			else:
				is_locked = true
				
		# Color and style based on state
		if is_today:
			card_style.bg_color = Color(1.0, 0.8, 0.2, 0.25)
			card_style.border_color = Color(1.0, 0.8, 0.2, 1.0) # Golden glow border
			card_style.shadow_color = Color(1.0, 0.8, 0.0, 0.3)
			card_style.shadow_size = 10
		elif is_claimed:
			card_style.bg_color = Color(0.1, 0.4, 0.1, 0.15)
			card_style.border_color = Color(0.2, 0.8, 0.2, 0.5)
		else:
			card_style.bg_color = Color(0.1, 0.1, 0.15, 0.4)
			card_style.border_color = Color(0.3, 0.3, 0.4, 0.3)
			
		card.add_theme_stylebox_override("panel", card_style)
		
		var card_vbox = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 10)
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Day Label
		var day_lbl = Label.new()
		day_lbl.text = "day %d" % day
		day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		day_lbl.add_theme_font_size_override("font_size", 18)
		if is_today:
			day_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		elif is_claimed:
			day_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		else:
			day_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		card_vbox.add_child(day_lbl)
		
		# Ruby Icon
		var icon = TextureRect.new()
		icon.texture = ResourceManager.get_texture("res://assets/ruby.png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if day == 7:
			icon.custom_minimum_size = Vector2(45, 45) # Large bonus ruby
			if not is_claimed:
				icon.ready.connect(func():
					var pulse_tween = icon.create_tween().set_loops()
					pulse_tween.tween_property(icon, "scale", Vector2(1.15, 1.15), 0.6).set_trans(Tween.TRANS_SINE)
					pulse_tween.tween_property(icon, "scale", Vector2(0.85, 0.85), 0.6).set_trans(Tween.TRANS_SINE)
				)
				icon.pivot_offset = Vector2(22.5, 22.5)
		else:
			icon.custom_minimum_size = Vector2(30, 30)
		card_vbox.add_child(icon)
		
		# Amount
		var amt_lbl = Label.new()
		var amt = 300 if day == 7 else 50
		amt_lbl.text = "+%d" % amt
		amt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amt_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		amt_lbl.add_theme_font_size_override("font_size", 20 if day == 7 else 18)
		if day == 7:
			amt_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) # Golden/Yellow
		else:
			amt_lbl.add_theme_color_override("font_color", Color.WHITE)
		card_vbox.add_child(amt_lbl)
		
		# Status indicator
		var status_lbl = Label.new()
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		status_lbl.add_theme_font_size_override("font_size", 14)
		if is_claimed:
			status_lbl.text = "claimed"
			status_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		elif is_today:
			status_lbl.text = "claim!"
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		else:
			status_lbl.text = "locked"
			status_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		card_vbox.add_child(status_lbl)
		
		card.add_child(card_vbox)
		cards_hbox.add_child(card)
		
	vbox.add_child(cards_hbox)
	
	# Actions row
	var actions_hbox = HBoxContainer.new()
	actions_hbox.add_theme_constant_override("separation", 20)
	actions_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var close_btn = UIFactory.create_glass_button("close", UIFactory.BLUE_COLOR)
	close_btn.pressed.connect(func():
		_set_main_menu_buttons_focusable(true)
		overlay.queue_free()
		if is_instance_valid(daily_btn):
			daily_btn.grab_focus()
	)
	
	var claim_btn: Button = null
	if claim_avail:
		var target_amount = 300 if today_candidate == 7 else 50
		claim_btn = UIFactory.create_glass_button("claim %d rubies!" % target_amount, UIFactory.GOLD_COLOR)
		claim_btn.pressed.connect(func():
			var res = SaveSystem.claim_daily_reward()
			if res.get("success", false):
				SoundManager.play_sfx("ruby")
				# Animate ruby counter update
				if is_instance_valid(_ruby_label):
					_ruby_label.text = "ruby: " + str(SaveSystem.global_rubies)
				
				# Animate a popup completion effect
				title.text = "claimed +%d rubies!" % res.get("amount", 0)
				title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
				subtitle.text = "congratulations! streak is now %d day(s)." % res.get("streak", 0)
				
				claim_btn.visible = false
				close_btn.text = "awesome!"
				close_btn.grab_focus()
				
				# Rebuild the calendar cards to show claimed state instantly
				for child in cards_hbox.get_children():
					child.queue_free()
				
				# Wait a frame to let cards free, then rebuild them
				await get_tree().process_frame
				
				var new_streak = SaveSystem.streak_count
				var new_claim_avail = SaveSystem.is_daily_reward_available()
				var new_today_candidate = SaveSystem.get_next_streak_day()
				
				for day in range(1, 8):
					var card = PanelContainer.new()
					card.custom_minimum_size = Vector2(110, 160)
					
					var card_style = StyleBoxFlat.new()
					card_style.corner_radius_top_left = 15
					card_style.corner_radius_top_right = 15
					card_style.corner_radius_bottom_right = 15
					card_style.corner_radius_bottom_left = 15
					card_style.border_width_left = 2
					card_style.border_width_top = 2
					card_style.border_width_right = 2
					card_style.border_width_bottom = 2
					
					var is_claimed = false
					var is_today = false
					var is_locked = false
					
					if new_claim_avail:
						if day < new_today_candidate:
							is_claimed = true
						elif day == new_today_candidate:
							is_today = true
						else:
							is_locked = true
					else:
						# just claimed today
						if day <= new_streak or (day == 7 and res.get("amount", 0) == 300):
							is_claimed = true
						else:
							is_locked = true
							
					if is_today:
						card_style.bg_color = Color(1.0, 0.8, 0.2, 0.25)
						card_style.border_color = Color(1.0, 0.8, 0.2, 1.0)
					elif is_claimed:
						card_style.bg_color = Color(0.1, 0.4, 0.1, 0.15)
						card_style.border_color = Color(0.2, 0.8, 0.2, 0.5)
					else:
						card_style.bg_color = Color(0.1, 0.1, 0.15, 0.4)
						card_style.border_color = Color(0.3, 0.3, 0.4, 0.3)
						
					card.add_theme_stylebox_override("panel", card_style)
					
					var card_vbox = VBoxContainer.new()
					card_vbox.add_theme_constant_override("separation", 10)
					card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
					
					var day_lbl = Label.new()
					day_lbl.text = "day %d" % day
					day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					day_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
					day_lbl.add_theme_font_size_override("font_size", 18)
					if is_today:
						day_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
					elif is_claimed:
						day_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
					else:
						day_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
					card_vbox.add_child(day_lbl)
					
					var icon = TextureRect.new()
					icon.texture = ResourceManager.get_texture("res://assets/ruby.png")
					icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					if day == 7:
						icon.custom_minimum_size = Vector2(45, 45)
						if not is_claimed:
							icon.ready.connect(func():
								var pulse_tween = icon.create_tween().set_loops()
								pulse_tween.tween_property(icon, "scale", Vector2(1.15, 1.15), 0.6).set_trans(Tween.TRANS_SINE)
								pulse_tween.tween_property(icon, "scale", Vector2(0.85, 0.85), 0.6).set_trans(Tween.TRANS_SINE)
							)
							icon.pivot_offset = Vector2(22.5, 22.5)
					else:
						icon.custom_minimum_size = Vector2(30, 30)
					card_vbox.add_child(icon)
					
					var amt_lbl = Label.new()
					var amt = 300 if day == 7 else 50
					amt_lbl.text = "+%d" % amt
					amt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					amt_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
					amt_lbl.add_theme_font_size_override("font_size", 20 if day == 7 else 18)
					if day == 7:
						amt_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
					else:
						amt_lbl.add_theme_color_override("font_color", Color.WHITE)
					card_vbox.add_child(amt_lbl)
					
					var status_lbl = Label.new()
					status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					status_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
					status_lbl.add_theme_font_size_override("font_size", 14)
					if is_claimed:
						status_lbl.text = "claimed"
						status_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
					elif is_today:
						status_lbl.text = "claim!"
						status_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
					else:
						status_lbl.text = "locked"
						status_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
					card_vbox.add_child(status_lbl)
					
					card.add_child(card_vbox)
					cards_hbox.add_child(card)
		)
		actions_hbox.add_child(claim_btn)
	
	actions_hbox.add_child(close_btn)
	vbox.add_child(actions_hbox)
	dialog.add_child(vbox)
	
	if claim_avail:
		# Trap focus neighborhood (directional keys)
		claim_btn.focus_neighbor_left = close_btn.get_path()
		claim_btn.focus_neighbor_right = close_btn.get_path()
		claim_btn.focus_neighbor_top = claim_btn.get_path()
		claim_btn.focus_neighbor_bottom = claim_btn.get_path()
		
		close_btn.focus_neighbor_left = claim_btn.get_path()
		close_btn.focus_neighbor_right = claim_btn.get_path()
		close_btn.focus_neighbor_top = close_btn.get_path()
		close_btn.focus_neighbor_bottom = close_btn.get_path()
		
		# Trap Tab focus loop (Tab/Shift+Tab keys)
		claim_btn.focus_next = close_btn.get_path()
		claim_btn.focus_previous = close_btn.get_path()
		close_btn.focus_next = claim_btn.get_path()
		close_btn.focus_previous = claim_btn.get_path()
	else:
		# Trap focus neighborhood for close button alone (directional keys)
		close_btn.focus_neighbor_left = close_btn.get_path()
		close_btn.focus_neighbor_right = close_btn.get_path()
		close_btn.focus_neighbor_top = close_btn.get_path()
		close_btn.focus_neighbor_bottom = close_btn.get_path()
		
		# Trap Tab focus loop for close button alone
		close_btn.focus_next = close_btn.get_path()
		close_btn.focus_previous = close_btn.get_path()
		
	if claim_avail:
		claim_btn.grab_focus()
	else:
		close_btn.grab_focus()


func _set_main_menu_buttons_focusable(enabled: bool):
	var mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if is_instance_valid(start_btn):
		start_btn.focus_mode = mode
	if is_instance_valid(tutorial_btn):
		tutorial_btn.focus_mode = mode
	if is_instance_valid(achievements_btn):
		achievements_btn.focus_mode = mode
	if is_instance_valid(daily_btn):
		daily_btn.focus_mode = mode
	if is_instance_valid(music_slider):
		music_slider.focus_mode = mode
	if is_instance_valid(sfx_slider):
		sfx_slider.focus_mode = mode
	if is_instance_valid(reset_btn):
		reset_btn.focus_mode = mode
	if is_instance_valid(_ruby_btn):
		_ruby_btn.focus_mode = mode

func _on_achievements_pressed():
	_set_main_menu_buttons_focusable(false)
	SoundManager.play_sfx("ui_click")
	
	var overlay = ColorRect.new()
	overlay.name = "AchievementsOverlay"
	overlay.color = Color(0, 0, 0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.09, 0.95)
	style.corner_radius_top_left = 25
	style.corner_radius_top_right = 25
	style.corner_radius_bottom_right = 25
	style.corner_radius_bottom_left = 25
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1, 0.85, 0.2, 0.9)
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0.8, 0.6, 0.0, 0.25)
	style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var outer_vbox = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 12)
	outer_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Header HBox: Title & Overall Progress
	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 4)
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var unlocked_num = AchievementManager.get_unlocked_count()
	var total_num = AchievementManager.get_total_count()
	var pct = (float(unlocked_num) / float(total_num)) * 100.0 if total_num > 0 else 0.0
	
	var title = Label.new()
	title.text = "🏆 achievements (%d / %d  •  %.0f%%)" % [unlocked_num, total_num, pct]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	header_vbox.add_child(title)
	
	# Overall Progress Bar
	var pbar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(500, 10)
	pbar.min_value = 0
	pbar.max_value = total_num
	pbar.value = unlocked_num
	pbar.show_percentage = false
	var pbar_bg = StyleBoxFlat.new()
	pbar_bg.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	pbar_bg.corner_radius_top_left = 5
	pbar_bg.corner_radius_top_right = 5
	pbar_bg.corner_radius_bottom_right = 5
	pbar_bg.corner_radius_bottom_left = 5
	var pbar_fg = StyleBoxFlat.new()
	pbar_fg.bg_color = Color(1.0, 0.85, 0.2, 0.9)
	pbar_fg.corner_radius_top_left = 5
	pbar_fg.corner_radius_top_right = 5
	pbar_fg.corner_radius_bottom_right = 5
	pbar_fg.corner_radius_bottom_left = 5
	pbar.add_theme_stylebox_override("background", pbar_bg)
	pbar.add_theme_stylebox_override("fill", pbar_fg)
	header_vbox.add_child(pbar)
	outer_vbox.add_child(header_vbox)
	
	# Category Filter Tabs
	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 8)
	tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var categories = [
		{"id": "all", "label": "all (75)"},
		{"id": "endless", "label": "endless"},
		{"id": "campaign", "label": "campaign"},
		{"id": "stars", "label": "stars"},
		{"id": "rubies", "label": "rubies"},
		{"id": "skills", "label": "skills"},
		{"id": "survival", "label": "survival"}
	]
	
	# Scrollable container for achievements
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var grid = VBoxContainer.new()
	grid.add_theme_constant_override("separation", 8)
	scroll.add_child(grid)
	
	var selected_cat = "all"
	var tab_buttons = []
	
	var populate_list = func(cat: String):
		for child in grid.get_children():
			child.queue_free()
			
		var achievements = AchievementManager.get_all_achievements(cat)
		var current_cat_heading = ""
		
		for ach in achievements:
			# Category subheader if in "all" view
			if cat == "all" and ach.category != current_cat_heading:
				current_cat_heading = ach.category
				var cat_lbl = Label.new()
				cat_lbl.text = "— " + current_cat_heading.to_upper() + " —"
				cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cat_lbl.add_theme_font_override("font", GAME_FONT)
				cat_lbl.add_theme_font_size_override("font_size", 20)
				cat_lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
				grid.add_child(cat_lbl)
			
			# Achievement row
			var row_panel = PanelContainer.new()
			var row_style = StyleBoxFlat.new()
			row_style.corner_radius_top_left = 12
			row_style.corner_radius_top_right = 12
			row_style.corner_radius_bottom_right = 12
			row_style.corner_radius_bottom_left = 12
			row_style.content_margin_left = 16
			row_style.content_margin_right = 16
			row_style.content_margin_top = 8
			row_style.content_margin_bottom = 8
			
			if ach.unlocked:
				row_style.bg_color = Color(0.12, 0.24, 0.12, 0.75)
				row_style.border_width_left = 2
				row_style.border_width_top = 2
				row_style.border_width_right = 2
				row_style.border_width_bottom = 2
				row_style.border_color = Color(0.3, 0.85, 0.3, 0.8)
			else:
				row_style.bg_color = Color(0.08, 0.08, 0.12, 0.5)
				row_style.border_width_left = 1
				row_style.border_width_top = 1
				row_style.border_width_right = 1
				row_style.border_width_bottom = 1
				row_style.border_color = Color(0.3, 0.3, 0.4, 0.3)
			
			row_panel.add_theme_stylebox_override("panel", row_style)
			
			var row_hbox = HBoxContainer.new()
			row_hbox.add_theme_constant_override("separation", 14)
			
			# Icon
			var icon_rect = TextureRect.new()
			icon_rect.texture = load(ach.icon)
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(46, 46)
			if not ach.unlocked:
				icon_rect.modulate = Color(0.25, 0.25, 0.3, 0.8)
			row_hbox.add_child(icon_rect)
			
			# Info VBox
			var info_vbox = VBoxContainer.new()
			info_vbox.add_theme_constant_override("separation", 2)
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var name_lbl = Label.new()
			name_lbl.text = ach.name
			name_lbl.add_theme_font_override("font", GAME_FONT)
			name_lbl.add_theme_font_size_override("font_size", 22)
			if ach.unlocked:
				name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
			else:
				name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			info_vbox.add_child(name_lbl)
			
			var desc_lbl = Label.new()
			desc_lbl.text = ach.desc
			desc_lbl.add_theme_font_override("font", GAME_FONT)
			desc_lbl.add_theme_font_size_override("font_size", 16)
			desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
			info_vbox.add_child(desc_lbl)
			
			row_hbox.add_child(info_vbox)
			
			# Status VBox
			var progress = ach.progress
			var status_vbox = VBoxContainer.new()
			status_vbox.add_theme_constant_override("separation", 2)
			status_vbox.custom_minimum_size = Vector2(130, 0)
			
			if ach.unlocked:
				var done_lbl = Label.new()
				done_lbl.text = "✓ UNLOCKED"
				done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				done_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
				done_lbl.add_theme_font_size_override("font_size", 18)
				done_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
				status_vbox.add_child(done_lbl)
			else:
				var prog_lbl = Label.new()
				prog_lbl.text = "%d / %d" % [progress.current, progress.target]
				prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				prog_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
				prog_lbl.add_theme_font_size_override("font_size", 18)
				prog_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				status_vbox.add_child(prog_lbl)
			
			var reward_lbl = Label.new()
			reward_lbl.text = "+%d rubies" % ach.reward
			reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			reward_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
			reward_lbl.add_theme_font_size_override("font_size", 15)
			if ach.unlocked:
				reward_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 0.3, 0.8))
			else:
				reward_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 0.7))
			status_vbox.add_child(reward_lbl)
			
			row_hbox.add_child(status_vbox)
			row_panel.add_child(row_hbox)
			grid.add_child(row_panel)
	
	for tab_info in categories:
		var tab_btn = Button.new()
		tab_btn.text = tab_info.label
		tab_btn.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		tab_btn.add_theme_font_size_override("font_size", 18)
		tab_btn.focus_mode = Control.FOCUS_ALL
		
		var t_style = StyleBoxFlat.new()
		t_style.bg_color = Color(0.12, 0.12, 0.2, 0.8)
		t_style.corner_radius_top_left = 10
		t_style.corner_radius_top_right = 10
		t_style.corner_radius_bottom_right = 10
		t_style.corner_radius_bottom_left = 10
		t_style.content_margin_left = 12
		t_style.content_margin_right = 12
		t_style.content_margin_top = 4
		t_style.content_margin_bottom = 4
		tab_btn.add_theme_stylebox_override("normal", t_style)
		
		var active_style = t_style.duplicate()
		active_style.bg_color = Color(0.3, 0.4, 0.8, 0.9)
		active_style.border_width_bottom = 2
		active_style.border_color = Color(1.0, 0.85, 0.2)
		
		var tab_id = tab_info.id
		tab_btn.pressed.connect(func():
			SoundManager.play_sfx("ui_click")
			selected_cat = tab_id
			for b in tab_buttons:
				b.remove_theme_stylebox_override("normal")
				b.add_theme_stylebox_override("normal", t_style)
			tab_btn.remove_theme_stylebox_override("normal")
			tab_btn.add_theme_stylebox_override("normal", active_style)
			populate_list.call(selected_cat)
		)
		
		tab_buttons.append(tab_btn)
		tabs_hbox.add_child(tab_btn)
	
	# Select initial "all" tab
	if tab_buttons.size() > 0:
		var init_style = StyleBoxFlat.new()
		init_style.bg_color = Color(0.3, 0.4, 0.8, 0.9)
		init_style.border_width_bottom = 2
		init_style.border_color = Color(1.0, 0.85, 0.2)
		init_style.corner_radius_top_left = 10
		init_style.corner_radius_top_right = 10
		init_style.corner_radius_bottom_right = 10
		init_style.corner_radius_bottom_left = 10
		init_style.content_margin_left = 12
		init_style.content_margin_right = 12
		init_style.content_margin_top = 4
		init_style.content_margin_bottom = 4
		tab_buttons[0].add_theme_stylebox_override("normal", init_style)
	
	outer_vbox.add_child(tabs_hbox)
	outer_vbox.add_child(scroll)
	
	# Close button
	var close_btn = UIFactory.create_glass_button("close", UIFactory.RED_COLOR)
	close_btn.pressed.connect(func():
		SoundManager.play_sfx("ui_click")
		_set_main_menu_buttons_focusable(true)
		overlay.queue_free()
		if is_instance_valid(achievements_btn):
			achievements_btn.grab_focus()
	)
	outer_vbox.add_child(close_btn)
	
	# Trap focus
	close_btn.focus_neighbor_left = close_btn.get_path()
	close_btn.focus_neighbor_right = close_btn.get_path()
	close_btn.focus_neighbor_top = close_btn.get_path()
	close_btn.focus_neighbor_bottom = close_btn.get_path()
	close_btn.focus_next = close_btn.get_path()
	close_btn.focus_previous = close_btn.get_path()
	
	panel.add_child(outer_vbox)
	populate_list.call("all")
	close_btn.grab_focus()


