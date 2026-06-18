extends Control

func _ready():
	BgmManager.play_menu_music()
	# Group buttons inside a VBox for tight vertical stacking
	var button_vbox = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 16)
	button_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var start_btn = $VBoxContainer/StartButton
	$VBoxContainer.remove_child(start_btn)
	button_vbox.add_child(start_btn)
	start_btn.pressed.connect(_on_start_pressed)
	
	var tutorial_btn = UIFactory.create_glass_button("tutorial", UIFactory.BLUE_COLOR)
	tutorial_btn.add_theme_font_size_override("font_size", 20)
	tutorial_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	button_vbox.add_child(tutorial_btn)
	
	$VBoxContainer.add_child(button_vbox)
	
	# Use UIFactory for central panels
	var score_panel = UIFactory.create_glass_panel(UIFactory.GOLD_COLOR)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var ruby_icon = TextureRect.new()
	ruby_icon.texture = ResourceManager.get_texture("res://assets/ruby.png")
	ruby_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruby_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ruby_icon.custom_minimum_size = Vector2(40, 40)
	
	var score_label = Label.new()
	score_label.text = "score: " + str(SaveSystem.global_score)
	score_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	score_label.add_theme_color_override("font_outline_color", Color.BLACK)
	score_label.add_theme_constant_override("outline_size", 8)
	
	hbox.add_child(ruby_icon)
	hbox.add_child(score_label)
	score_panel.add_child(hbox)
	
	var score_margin = MarginContainer.new()
	score_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	score_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	score_margin.add_theme_constant_override("margin_top", 30)
	score_margin.add_theme_constant_override("margin_right", 30)
	score_margin.add_child(score_panel)
	add_child(score_margin)
	
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
	
	var music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = SaveSystem.music_volume
	music_slider.focus_mode = Control.FOCUS_NONE
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
	
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = SaveSystem.sfx_volume
	sfx_slider.focus_mode = Control.FOCUS_NONE
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

	# Reset Button using UIFactory (Red Style)
	var reset_btn = UIFactory.create_glass_button("reset", UIFactory.RED_COLOR)
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



func _on_start_pressed():
	SceneTransition.transition_to("res://scenes/level_select.tscn")

func _on_tutorial_pressed():
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
		{"icon": "res://assets/custom_player.png", "keys": "space / tap screen", "desc": "launch into orbit or release tether gravity field."},
		{"icon": "res://assets/custom_player.png", "keys": "click glide button", "desc": "redirect velocity in outer space (buy glides in menu)."},
		{"icon": "res://assets/custom_player.png", "keys": "shift / click speed button", "desc": "speed up outer space flying (buy speed boosts in menu)."},
		{"icon": "res://assets/ruby.png", "keys": "space rubies", "desc": "collect glowing rubies around levels to increase score."},
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
		tut_overlay.queue_free()
	)
	vbox.add_child(close_btn)

func _on_reset_pressed():
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
	warn_msg.text = "all progress, stars and score\nwill be permanently deleted!"
	warn_msg.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	warn_msg.add_theme_font_size_override("font_size", 28)
	warn_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warn_msg)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var cancel_btn = UIFactory.create_glass_button("cancel", UIFactory.BLUE_COLOR)
	cancel_btn.pressed.connect(func():
		overlay.queue_free()
		dialog.queue_free()
	)

	var confirm_btn = UIFactory.create_glass_button("yes, reset!", UIFactory.RED_COLOR)
	confirm_btn.pressed.connect(func():
		SaveSystem.unlocked_levels = 1
		SaveSystem.global_score = 0
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
