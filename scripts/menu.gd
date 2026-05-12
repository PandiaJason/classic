extends Control

func _ready():
	BgmManager.play_menu_music()
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	
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
	
	# Music Toggle using UIFactory — restore saved state
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_idx, not SaveSystem.music_on)
	var music_text = " music: on" if SaveSystem.music_on else " music: off"
	var music_btn = UIFactory.create_glass_button(music_text.strip_edges(), UIFactory.BLUE_COLOR)
	var music_margin = MarginContainer.new()
	music_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	music_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	music_margin.add_theme_constant_override("margin_bottom", 30)
	music_margin.add_theme_constant_override("margin_left", 30)
	music_margin.add_child(music_btn)
	add_child(music_margin)
	
	music_btn.pressed.connect(_on_music_pressed.bind(music_btn))
	
	# Calculate and Display Delivery Rate
	var unlocked_count = 0
	var total_stars = 0
	for i in range(1, 31):
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
	copyright.text = "copyrighted by @pandiajason"
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

func _on_music_pressed(btn: Button):
	var bus_idx = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(bus_idx)
	AudioServer.set_bus_mute(bus_idx, not is_muted)
	btn.text = " music: off" if not is_muted else " music: on"
	SaveSystem.music_on = is_muted  # was muted, now it's on (and vice versa)
	SaveSystem.save_data()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

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
		for i in range(1, 31):
			SaveSystem.level_stars[i] = 0
		SaveSystem.save_data()
		get_tree().reload_current_scene()
	)

	btn_row.add_child(cancel_btn)
	btn_row.add_child(confirm_btn)
	vbox.add_child(btn_row)
	dialog.add_child(vbox)
